import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/services/auth_service.dart';
import 'package:shared_cab/core/services/ride_join_request_store.dart';
import 'package:shared_cab/core/services/ride_request_queue.dart';
import 'package:shared_cab/core/utils/ride_trip_utils.dart';
import 'package:shared_cab/models/ride_request_model.dart';

class RideService {
  RideService._();

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static bool get _canUseFirestore => AuthService.isFirebaseReady;
  static CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');
  // Source of truth remains embedded joinRequests in ride documents.
  // requests subcollection is a write-through projection for scalable reads.
  static const RideJoinRequestStore _joinRequestStore =
      FirestoreRideJoinRequestStore();

  @visibleForTesting
  static List<RideRequest> ridesToAutoCancelOnPublish({
    required Iterable<RideRequest> existingRides,
    required String publishingRideId,
  }) {
    return existingRides
        .where(
          (ride) =>
              ride.id != publishingRideId &&
              RideTripUtils.shouldAutoCancelRide(ride.status),
        )
        .toList();
  }

  @visibleForTesting
  static void ensureHostMutationAllowed({
    required RideRequest ride,
    required String? actingUserId,
  }) {
    if (actingUserId == null || actingUserId.isEmpty) {
      throw StateError('You must be signed in to modify rides.');
    }
    if (ride.userId != actingUserId) {
      throw StateError('Only the ride host can modify this ride.');
    }
  }

  @visibleForTesting
  static void ensureRequesterMutationAllowed({
    required String requesterId,
    required String? actingUserId,
  }) {
    if (actingUserId == null || actingUserId.isEmpty) {
      throw StateError('You must be signed in to manage ride requests.');
    }
    if (requesterId != actingUserId) {
      throw StateError('You can only manage your own ride request.');
    }
  }

  static String _requireCurrentUserId() {
    final currentUid = AuthService.currentUserId;
    if (currentUid == null || currentUid.isEmpty) {
      throw StateError('You must be signed in to modify rides.');
    }
    return currentUid;
  }

  static Future<bool> _runQueueMutation({
    required String rideId,
    required void Function(RideRequest ride) authorize,
    required RideRequestMutation Function(RideRequest ride) mutate,
  }) async {
    final rideRef = _rides.doc(rideId);
    var changed = false;

    await _firestore.runTransaction((transaction) async {
      final timestamp = DateTime.now();
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final currentRide = RideRequest.fromMap(snapshot.data()!);
      authorize(currentRide);
      final mutation = mutate(currentRide);
      if (!mutation.changed) return;

      changed = true;
      transaction.set(rideRef, mutation.ride.toMap());
      _joinRequestStore.syncQueueProjectionInTransaction(
        transaction: transaction,
        rideRef: rideRef,
        previousJoinRequests: currentRide.joinRequests,
        nextJoinRequests: mutation.ride.joinRequests,
        now: timestamp,
      );
    });

    return changed;
  }

  static Future<void> publishRide(RideRequest ride) async {
    if (!_canUseFirestore) return;
    final currentUid = _requireCurrentUserId();
    ensureHostMutationAllowed(ride: ride, actingUserId: currentUid);

    final snapshot = await _rides.where('userId', isEqualTo: currentUid).get();
    final existingRides = snapshot.docs
        .map((doc) => RideRequest.fromMap(doc.data()))
        .toList();
    final existingById = {
      for (final existingRide in existingRides) existingRide.id: existingRide,
    };
    final ridesToCancel = ridesToAutoCancelOnPublish(
      existingRides: existingRides,
      publishingRideId: ride.id,
    );
    final cancellableIds = ridesToCancel.map((item) => item.id).toSet();
    final batch = _firestore.batch();
    final timestamp = DateTime.now();

    for (final doc in snapshot.docs) {
      if (!cancellableIds.contains(doc.id)) {
        continue;
      }

      final currentRide = RideRequest.fromMap(doc.data());
      final cancelledRide = RideRequestQueue.clearQueueForCancellation(
        currentRide,
      ).copyWith(status: RideStatus.cancelled);

      batch.set(doc.reference, {
        ...cancelledRide.toMap(),
        'cabLat': null,
        'cabLng': null,
        'cabSegmentIndex': null,
        'cabSegmentProgress': null,
        'cabBearing': null,
        'cabUpdatedAt': null,
      });
      _joinRequestStore.syncQueueProjectionInBatch(
        batch: batch,
        rideRef: doc.reference,
        previousJoinRequests: currentRide.joinRequests,
        nextJoinRequests: cancelledRide.joinRequests,
        now: timestamp,
      );
    }

    final publishingRideRef = _rides.doc(ride.id);
    batch.set(publishingRideRef, ride.toMap());
    _joinRequestStore.syncQueueProjectionInBatch(
      batch: batch,
      rideRef: publishingRideRef,
      previousJoinRequests: existingById[ride.id]?.joinRequests ?? const [],
      nextJoinRequests: ride.joinRequests,
      now: timestamp,
    );
    await batch.commit();
  }

  /// Returns backend-discoverable rides only.
  /// MatchingPipeline owns freshness, identity, eligibility, and ranking.
  static Stream<List<RideRequest>> availableRidesStream() {
    if (!_canUseFirestore) return Stream.value(const []);

    return _rides.snapshots().map((snapshot) {
      final rides = snapshot.docs
          .map((doc) => RideRequest.fromMap(doc.data()))
          .where(RideRequestQueue.isDiscoverable)
          .toList();
      rides.sort((left, right) => right.createdAt.compareTo(left.createdAt));
      return rides;
    });
  }

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
    ensureRequesterMutationAllowed(
      requesterId: requesterId,
      actingUserId: AuthService.currentUserId,
    );
    final rideRef = _rides.doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final timestamp = DateTime.now();
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Ride not found.');
      }

      final currentRide = RideRequest.fromMap(snapshot.data()!);
      final mutation = RideRequestQueue.enqueueRequest(
        currentRide,
        requesterId: requesterId,
        requesterName: requesterName,
        requesterGender: requesterGender,
        requesterPickup: requesterPickup,
        requesterDropoff: requesterDropoff,
        requesterPickupLat: requesterPickupLat,
        requesterPickupLng: requesterPickupLng,
      );
      transaction.set(rideRef, mutation.ride.toMap());
      _joinRequestStore.syncQueueProjectionInTransaction(
        transaction: transaction,
        rideRef: rideRef,
        previousJoinRequests: currentRide.joinRequests,
        nextJoinRequests: mutation.ride.joinRequests,
        now: timestamp,
      );
    });
  }

  static Future<bool> cancelPendingRequest(
    String rideId, {
    String? requesterId,
  }) async {
    if (!_canUseFirestore) return false;
    final currentUid = _requireCurrentUserId();
    final effectiveRequesterId = requesterId ?? currentUid;
    ensureRequesterMutationAllowed(
      requesterId: effectiveRequesterId,
      actingUserId: currentUid,
    );

    return _runQueueMutation(
      rideId: rideId,
      authorize: (_) {},
      mutate: (ride) => RideRequestQueue.cancelPendingRequest(
        ride,
        requesterId: effectiveRequesterId,
      ),
    );
  }

  static Future<bool> acceptRequest(
    String rideId, {
    required String requesterId,
    required bool waitForAnotherRider,
  }) async {
    if (!_canUseFirestore) return false;
    final currentUid = _requireCurrentUserId();
    return _runQueueMutation(
      rideId: rideId,
      authorize: (ride) =>
          ensureHostMutationAllowed(ride: ride, actingUserId: currentUid),
      mutate: (ride) => RideRequestQueue.acceptRequest(
        ride,
        requesterId: requesterId,
        waitForAnotherRider: waitForAnotherRider,
      ),
    );
  }

  static Future<bool> declineRequest(
    String rideId, {
    required String requesterId,
    String? reason,
  }) async {
    if (!_canUseFirestore) return false;
    final currentUid = _requireCurrentUserId();
    return _runQueueMutation(
      rideId: rideId,
      authorize: (ride) =>
          ensureHostMutationAllowed(ride: ride, actingUserId: currentUid),
      mutate: (ride) => RideRequestQueue.declineRequest(
        ride,
        requesterId: requesterId,
        reason: reason,
      ),
    );
  }

  static Future<bool> cancelJoinedRide(String rideId) async {
    if (!_canUseFirestore) return false;
    final currentUid = _requireCurrentUserId();
    return _runQueueMutation(
      rideId: rideId,
      authorize: (_) {},
      mutate: (ride) => RideRequestQueue.cancelJoinedRide(
        ride,
        riderId: currentUid,
      ),
    );
  }

  static Future<void> updateCabSyncState({
    required String rideId,
    required LatLng cabPosition,
    required int segmentIndex,
    required double segmentProgress,
    required double bearingDegrees,
  }) async {
    if (!_canUseFirestore) return;
    final currentUid = _requireCurrentUserId();
    final rideRef = _rides.doc(rideId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Ride not found.');
      }
      final ride = RideRequest.fromMap(snapshot.data()!);
      ensureHostMutationAllowed(ride: ride, actingUserId: currentUid);
      transaction.update(rideRef, {
        'cabLat': cabPosition.latitude,
        'cabLng': cabPosition.longitude,
        'cabSegmentIndex': segmentIndex,
        'cabSegmentProgress': segmentProgress,
        'cabBearing': bearingDegrees,
        'cabUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  static Future<void> updateRideStatus(String rideId, RideStatus status) async {
    if (!_canUseFirestore) return;
    final currentUid = _requireCurrentUserId();
    final rideRef = _rides.doc(rideId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Ride not found.');
      }
      final ride = RideRequest.fromMap(snapshot.data()!);
      ensureHostMutationAllowed(ride: ride, actingUserId: currentUid);
      transaction.update(rideRef, {'status': status.name});
    });
  }

  static Future<RideRequest?> getRide(String rideId) async {
    if (!_canUseFirestore) return null;
    final doc = await _rides.doc(rideId).get();
    if (doc.exists && doc.data() != null) {
      return RideRequest.fromMap(doc.data()!);
    }
    return null;
  }

  static Stream<RideRequest?> rideStream(String rideId) {
    if (!_canUseFirestore) return Stream.value(null);
    return _rides.doc(rideId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return RideRequest.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
