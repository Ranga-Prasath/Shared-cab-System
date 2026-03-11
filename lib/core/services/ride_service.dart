// -- Shared Cab System --
// Ride Service — publish, stream, and join rides via Cloud Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/services/auth_service.dart';
import 'package:shared_cab/models/ride_request_model.dart';

class RideService {
  RideService._();

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static bool get _canUseFirestore => AuthService.isFirebaseReady;
  static CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  /// Cancel all previous pending rides from the current user.
  static Future<void> cancelMyPreviousRides() async {
    if (!_canUseFirestore) return;
    final currentUid = AuthService.currentUserId;
    if (currentUid == null) return;

    final snapshot = await _rides.where('userId', isEqualTo: currentUid).get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status']?.toString() ?? '';
      if (status != 'completed' && status != 'cancelled') {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'requesterId': null,
          'requesterName': null,
          'requesterGender': null,
          'requesterPickup': null,
          'requesterDropoff': null,
          'requesterPickupLat': null,
          'requesterPickupLng': null,
          'acceptedPickupStops': const [],
          'cabLat': null,
          'cabLng': null,
          'cabSegmentIndex': null,
          'cabSegmentProgress': null,
          'cabBearing': null,
          'cabUpdatedAt': null,
        });
      }
    }
    await batch.commit();
  }

  /// Publish a new ride request to Firestore.
  /// Automatically cancels any previous pending rides from this user.
  static Future<void> publishRide(RideRequest ride) async {
    if (!_canUseFirestore) return;
    await cancelMyPreviousRides();
    await _rides.doc(ride.id).set(ride.toMap());
  }

  /// Stream of all pending rides from OTHER users (not the current user).
  /// Only includes recent rides (created within last 30 minutes).
  static Stream<List<RideRequest>> availableRidesStream() {
    if (!_canUseFirestore) return Stream.value([]);

    return _rides.snapshots().map((snapshot) {
      final now = DateTime.now();
      final currentUid = AuthService.currentUserId;
      final rides = snapshot.docs
          .map((doc) => RideRequest.fromMap(doc.data()))
          .where(
            (ride) =>
                ride.status == RideStatus.pending &&
                (currentUid == null || ride.userId != currentUid) &&
                now.difference(ride.createdAt).inMinutes <= 30,
          )
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
    double? requesterPickupLat,
    double? requesterPickupLng,
  }) async {
    if (!_canUseFirestore) return;
    await _rides.doc(rideId).update({
      'status': 'requested',
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterGender': requesterGender,
      'requesterPickup': requesterPickup,
      'requesterDropoff': requesterDropoff,
      'requesterPickupLat': requesterPickupLat,
      'requesterPickupLng': requesterPickupLng,
    });
  }

  /// User 1 ACCEPTS the request.
<<<<<<< HEAD
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
=======
  /// Adds the requester to coRiderIds, sets status to 'matched'.
  static Future<void> acceptRequest(
    String rideId, {
    required bool waitForAnotherRider,
  }) async {
    if (!_canUseFirestore) return;
    final rideRef = _rides.doc(rideId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final requesterId = data['requesterId']?.toString() ?? '';
      if (requesterId.isEmpty) return;

      final nextStatus = waitForAnotherRider ? 'pending' : 'matched';
      final currentCoRiders = List<String>.from(data['coRiderIds'] ?? const []);
      final updatedCoRiders = [...currentCoRiders];
      if (!updatedCoRiders.contains(requesterId)) {
        updatedCoRiders.add(requesterId);
      }

      final acceptedStops = _readAcceptedPickupStops(data);
      final requesterPickupStop = _buildRequesterPickupStop(data);
      final updatedStops = requesterPickupStop == null
          ? acceptedStops
          : _upsertAcceptedPickupStop(acceptedStops, requesterPickupStop);

      transaction.update(rideRef, {
        'status': nextStatus,
        'coRiderIds': updatedCoRiders,
        'acceptedPickupStops': updatedStops
            .map((pickupStop) => pickupStop.toMap())
            .toList(),
        'waitForAnotherRider': waitForAnotherRider,
        'readyToProceed': !waitForAnotherRider,
        'requesterId': null,
        'requesterName': null,
        'requesterGender': null,
        'requesterPickup': null,
        'requesterDropoff': null,
        'requesterPickupLat': null,
        'requesterPickupLng': null,
      });
>>>>>>> 80114ce (Polish trip routing and demo verification)
    });
  }

  /// User 1 DECLINES the request.
  static Future<void> declineRequest(String rideId) async {
    if (!_canUseFirestore) return;
    await _rides.doc(rideId).update({
      'status': 'declined',
      'requesterId': null,
      'requesterName': null,
      'requesterGender': null,
      'requesterPickup': null,
      'requesterDropoff': null,
<<<<<<< HEAD
=======
      'requesterPickupLat': null,
      'requesterPickupLng': null,
>>>>>>> 80114ce (Polish trip routing and demo verification)
    });
    // After a brief moment, set back to pending so ride is available again
    await Future.delayed(const Duration(seconds: 3));
    await _rides.doc(rideId).update({'status': 'pending'});
  }

  /// A joined co-rider can leave while waiting for additional riders.
  static Future<void> cancelJoinedRide(String rideId) async {
    if (!_canUseFirestore) return;
    final currentUid = AuthService.currentUserId;
    if (currentUid == null) return;

    final rideRef = _rides.doc(rideId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final currentCoRiders = List<String>.from(data['coRiderIds'] ?? const []);
      final updatedCoRiders = [...currentCoRiders]
        ..removeWhere((id) => id == currentUid);

      final updatePayload = <String, dynamic>{
        'coRiderIds': updatedCoRiders,
        'acceptedPickupStops': _readAcceptedPickupStops(data)
            .where((pickupStop) => pickupStop.riderId != currentUid)
            .map((pickupStop) => pickupStop.toMap())
            .toList(),
      };

      if ((data['requesterId'] as String?) == currentUid) {
        updatePayload.addAll({
          'requesterId': null,
          'requesterName': null,
          'requesterGender': null,
          'requesterPickup': null,
          'requesterDropoff': null,
          'requesterPickupLat': null,
          'requesterPickupLng': null,
        });
      }

      if (updatedCoRiders.isEmpty) {
        updatePayload.addAll({
          'status': 'pending',
          'waitForAnotherRider': false,
          'readyToProceed': false,
        });
      }

      transaction.update(rideRef, updatePayload);
    });
  }

  /// Old method — kept for backward compatibility. Directly joins a ride.
  static Future<void> joinRide(String rideId) async {
    if (!_canUseFirestore) return;
    final currentUid = AuthService.currentUserId;
    if (currentUid == null) return;

    await _rides.doc(rideId).update({
      'coRiderIds': FieldValue.arrayUnion([currentUid]),
      'status': 'matched',
    });
  }

  /// Publishes authoritative cab simulation state for all participants.
  static Future<void> updateCabSyncState({
    required String rideId,
    required LatLng cabPosition,
    required int segmentIndex,
    required double segmentProgress,
    required double bearingDegrees,
  }) async {
    if (!_canUseFirestore) return;
    await _rides.doc(rideId).update({
      'cabLat': cabPosition.latitude,
      'cabLng': cabPosition.longitude,
      'cabSegmentIndex': segmentIndex,
      'cabSegmentProgress': segmentProgress,
      'cabBearing': bearingDegrees,
      'cabUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Updates ride status during the active trip lifecycle.
  static Future<void> updateRideStatus(String rideId, RideStatus status) async {
    if (!_canUseFirestore) return;
    await _rides.doc(rideId).update({'status': status.name});
  }

  /// Cancel / soft-delete a ride.
  static Future<void> cancelRide(String rideId) async {
    if (!_canUseFirestore) return;
    await _rides.doc(rideId).update({'status': 'cancelled'});
  }

  /// Get a single ride by ID.
  static Future<RideRequest?> getRide(String rideId) async {
    if (!_canUseFirestore) return null;
    final doc = await _rides.doc(rideId).get();
    if (doc.exists && doc.data() != null) {
      return RideRequest.fromMap(doc.data()!);
    }
    return null;
  }

  /// Stream a single ride for real-time updates.
  static Stream<RideRequest?> rideStream(String rideId) {
    if (!_canUseFirestore) return Stream.value(null);
    return _rides.doc(rideId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return RideRequest.fromMap(doc.data()!);
      }
      return null;
    });
  }

  static List<RidePickupStop> _readAcceptedPickupStops(
    Map<String, dynamic> data,
  ) {
    final rawStops = data['acceptedPickupStops'] as List<dynamic>? ?? const [];
    return rawStops
        .whereType<Map>()
        .map((item) => RidePickupStop.fromMap(Map<String, dynamic>.from(item)))
        .where((pickupStop) => pickupStop.riderId.isNotEmpty)
        .toList();
  }

  static RidePickupStop? _buildRequesterPickupStop(Map<String, dynamic> data) {
    final requesterId = data['requesterId']?.toString() ?? '';
    final latitude = (data['requesterPickupLat'] as num?)?.toDouble();
    final longitude = (data['requesterPickupLng'] as num?)?.toDouble();
    if (requesterId.isEmpty || latitude == null || longitude == null) {
      return null;
    }

    return RidePickupStop(
      riderId: requesterId,
      riderName: data['requesterName']?.toString() ?? '',
      latitude: latitude,
      longitude: longitude,
      address: data['requesterPickup']?.toString() ?? '',
    );
  }

  static List<RidePickupStop> _upsertAcceptedPickupStop(
    List<RidePickupStop> currentStops,
    RidePickupStop nextStop,
  ) {
    final updatedStops = [
      for (final currentStop in currentStops)
        if (currentStop.riderId != nextStop.riderId) currentStop,
      nextStop,
    ];
    return updatedStops;
  }
}
