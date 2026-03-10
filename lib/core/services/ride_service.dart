// -- Shared Cab System --
// Ride Service — publish, stream, and join rides via Cloud Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_cab/models/ride_request_model.dart';

class RideService {
  RideService._();

  static final _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  /// Cancel all previous pending rides from the current user.
  static Future<void> cancelMyPreviousRides() async {
    final currentUid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final snapshot = await _rides.where('userId', isEqualTo: currentUid).get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'pending' || data['status'] == 'requested') {
        batch.update(doc.reference, {'status': 'cancelled'});
      }
    }
    await batch.commit();
  }

  /// Publish a new ride request to Firestore.
  /// Automatically cancels any previous pending rides from this user.
  static Future<void> publishRide(RideRequest ride) async {
    await cancelMyPreviousRides();
    await _rides.doc(ride.id).set(ride.toMap());
  }

  /// Stream of all pending rides from OTHER users (not the current user).
  /// Only includes recent rides (created within last 30 minutes).
  static Stream<List<RideRequest>> availableRidesStream() {
    final currentUid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return Stream.value([]);

    return _rides.snapshots().map((snapshot) {
      final now = DateTime.now();
      final rides = snapshot.docs
          .map((doc) => RideRequest.fromMap(doc.data()))
          .where((ride) =>
              ride.userId != currentUid &&
              ride.status == RideStatus.pending &&
              now.difference(ride.createdAt).inMinutes <= 30)
          .toList();

      rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rides;
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // REQUEST / ACCEPT / DECLINE FLOW
  // ─────────────────────────────────────────────────────────────────

  /// User 2 sends a REQUEST to join User 1's ride.
  /// Sets ride status to 'requested' and stores the requester's info.
  static Future<void> requestToJoin({
    required String rideId,
    required String requesterId,
    required String requesterName,
    String requesterGender = '',
    String requesterPickup = '',
    String requesterDropoff = '',
  }) async {
    await _rides.doc(rideId).update({
      'status': 'requested',
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterGender': requesterGender,
      'requesterPickup': requesterPickup,
      'requesterDropoff': requesterDropoff,
    });
  }

  /// User 1 ACCEPTS the request.
  /// If waitForMore is true, sets status to 'acceptedWaiting' (waiting for more riders).
  /// If false, sets status to 'matched' (proceed immediately).
  static Future<void> acceptRequest(String rideId, {bool waitForMore = false}) async {
    final doc = await _rides.doc(rideId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final requesterId = data['requesterId'];

    await _rides.doc(rideId).update({
      'status': waitForMore ? 'acceptedWaiting' : 'matched',
      'coRiderIds': FieldValue.arrayUnion([requesterId]),
      // Clear requester fields so new requests can come in
      'requesterId': null,
      'requesterName': null,
      'requesterGender': null,
      'requesterPickup': null,
      'requesterDropoff': null,
    });
  }

  /// User 1 decides to PROCEED the ride (stop waiting for more riders).
  /// Changes status from 'acceptedWaiting' to 'matched'.
  static Future<void> proceedRide(String rideId) async {
    await _rides.doc(rideId).update({
      'status': 'matched',
    });
  }

  /// A co-rider leaves the ride while in acceptedWaiting state.
  static Future<void> leaveRide(String rideId) async {
    final currentUid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    await _rides.doc(rideId).update({
      'coRiderIds': FieldValue.arrayRemove([currentUid]),
    });
  }

  /// User 1 DECLINES the request.
  static Future<void> declineRequest(String rideId) async {
    await _rides.doc(rideId).update({
      'status': 'declined',
      'requesterId': null,
      'requesterName': null,
      'requesterGender': null,
      'requesterPickup': null,
      'requesterDropoff': null,
    });
    // After a brief moment, set back to pending so ride is available again
    await Future.delayed(const Duration(seconds: 3));
    await _rides.doc(rideId).update({
      'status': 'pending',
    });
  }

  /// Old method — kept for backward compatibility. Directly joins a ride.
  static Future<void> joinRide(String rideId) async {
    final currentUid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    await _rides.doc(rideId).update({
      'coRiderIds': FieldValue.arrayUnion([currentUid]),
      'status': 'matched',
    });
  }

  /// Cancel / soft-delete a ride.
  static Future<void> cancelRide(String rideId) async {
    await _rides.doc(rideId).update({'status': 'cancelled'});
  }

  /// Get a single ride by ID.
  static Future<RideRequest?> getRide(String rideId) async {
    final doc = await _rides.doc(rideId).get();
    if (doc.exists && doc.data() != null) {
      return RideRequest.fromMap(doc.data()!);
    }
    return null;
  }

  /// Stream a single ride for real-time updates.
  static Stream<RideRequest?> rideStream(String rideId) {
    return _rides.doc(rideId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return RideRequest.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
