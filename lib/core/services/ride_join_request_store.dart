import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_cab/models/ride_request_model.dart';

abstract class RideJoinRequestStore {
  const RideJoinRequestStore();

  void syncQueueProjectionInTransaction({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> rideRef,
    required List<RideJoinRequest> previousJoinRequests,
    required List<RideJoinRequest> nextJoinRequests,
    required DateTime now,
  });

  void syncQueueProjectionInBatch({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> rideRef,
    required List<RideJoinRequest> previousJoinRequests,
    required List<RideJoinRequest> nextJoinRequests,
    required DateTime now,
  });
}

class FirestoreRideJoinRequestStore extends RideJoinRequestStore {
  const FirestoreRideJoinRequestStore();

  static const String projectionClearedReason = 'Ride is no longer available.';

  @override
  void syncQueueProjectionInTransaction({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> rideRef,
    required List<RideJoinRequest> previousJoinRequests,
    required List<RideJoinRequest> nextJoinRequests,
    required DateTime now,
  }) {
    _syncProjection(
      rideRef: rideRef,
      previousJoinRequests: previousJoinRequests,
      nextJoinRequests: nextJoinRequests,
      now: now,
      writer: (requestRef, data) => transaction.set(requestRef, data),
    );
  }

  @override
  void syncQueueProjectionInBatch({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> rideRef,
    required List<RideJoinRequest> previousJoinRequests,
    required List<RideJoinRequest> nextJoinRequests,
    required DateTime now,
  }) {
    _syncProjection(
      rideRef: rideRef,
      previousJoinRequests: previousJoinRequests,
      nextJoinRequests: nextJoinRequests,
      now: now,
      writer: (requestRef, data) => batch.set(requestRef, data),
    );
  }

  void _syncProjection({
    required DocumentReference<Map<String, dynamic>> rideRef,
    required List<RideJoinRequest> previousJoinRequests,
    required List<RideJoinRequest> nextJoinRequests,
    required DateTime now,
    required void Function(
      DocumentReference<Map<String, dynamic>> requestRef,
      Map<String, dynamic> data,
    )
    writer,
  }) {
    final requestsCollection = rideRef.collection('requests');
    final nowMs = now.millisecondsSinceEpoch;
    final previousById = {
      for (final request in previousJoinRequests)
        if (request.requesterId.isNotEmpty) request.requesterId: request,
    };
    final nextById = {
      for (final request in nextJoinRequests)
        if (request.requesterId.isNotEmpty) request.requesterId: request,
    };

    for (final entry in nextById.entries) {
      writer(
        requestsCollection.doc(entry.key),
        _projectionMap(entry.value, rideId: rideRef.id, nowMs: nowMs),
      );
    }

    for (final entry in previousById.entries) {
      if (nextById.containsKey(entry.key)) continue;
      writer(
        requestsCollection.doc(entry.key),
        _projectionMap(
          _projectionCleared(entry.value, now: now),
          rideId: rideRef.id,
          nowMs: nowMs,
        ),
      );
    }
  }

  RideJoinRequest _projectionCleared(RideJoinRequest request, {required DateTime now}) {
    return request.copyWith(
      status: RideJoinRequestStatus.declined,
      updatedAt: now,
      statusUpdatedAt: now,
      resolvedAt: now,
      statusReason: projectionClearedReason,
      requestClientReasonCode: 'projection_cleared',
      clearRequestExpiryAt: true,
    );
  }

  Map<String, dynamic> _projectionMap(
    RideJoinRequest request, {
    required String rideId,
    required int nowMs,
  }) {
    return {
      ...request.toMap(),
      'rideId': rideId,
      'projectionUpdatedAt': nowMs,
    };
  }
}
