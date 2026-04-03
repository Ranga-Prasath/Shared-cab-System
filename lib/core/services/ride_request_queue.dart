import 'package:shared_cab/core/services/ride_queue_policy.dart';
import 'package:shared_cab/models/ride_request_model.dart';

class RideRequestMutation {
  const RideRequestMutation({required this.ride, required this.changed});

  final RideRequest ride;
  final bool changed;
}

class RideRequestQueue {
  RideRequestQueue._();

  static const String requesterCancelledReason =
      'Requester cancelled the ride.';
  static const String hostDeclinedReason = 'Host declined the ride request.';
  static const String rideFilledReason = 'Ride is no longer available.';
  static const String joinedRiderCancelledReason =
      'Joined rider left before the trip started.';
  static const String requestExpiredReason = 'Request expired.';

  static bool isDiscoverable(RideRequest ride) {
    return ride.status == RideStatus.pending ||
        ride.status == RideStatus.requested;
  }

  static RideRequestMutation enqueueRequest(
    RideRequest ride, {
    required String requesterId,
    required String requesterName,
    required String requesterGender,
    required String requesterPickup,
    required String requesterDropoff,
    required double? requesterPickupLat,
    required double? requesterPickupLng,
    DateTime? now,
    RideQueuePolicy policy = const RideQueuePolicy(),
  }) {
    final timestamp = now ?? DateTime.now();
    final normalized = _normalizeForPendingExpiry(ride, timestamp);
    final effectiveRide = normalized.ride;

    if (requesterId.isEmpty) {
      throw StateError('Requester id is required.');
    }
    if (requesterId == effectiveRide.userId) {
      throw StateError('You cannot request your own ride.');
    }
    if (!isDiscoverable(effectiveRide)) {
      throw StateError('This ride is no longer accepting requests.');
    }
    if (_hasReachedCapacity(effectiveRide)) {
      throw StateError('This ride is already full.');
    }
    if (effectiveRide.coRiderIds.contains(requesterId)) {
      throw StateError('You already joined this ride.');
    }

    final requests = List<RideJoinRequest>.from(effectiveRide.joinRequests);
    final index = requests.indexWhere(
      (request) => request.requesterId == requesterId,
    );
    if (index < 0 &&
        _pendingRequestCount(requests) >= policy.maxPendingRequests) {
      throw StateError('Ride already has maximum pending requests.');
    }

    final expiryAt = timestamp.add(
      Duration(minutes: policy.requestExpiryMinutes),
    );
    final nextRequest = RideJoinRequest(
      requesterId: requesterId,
      requesterName: requesterName,
      requesterGender: requesterGender,
      requesterPickup: requesterPickup,
      requesterDropoff: requesterDropoff,
      requesterPickupLat: requesterPickupLat,
      requesterPickupLng: requesterPickupLng,
      status: RideJoinRequestStatus.pending,
      requestedAt: timestamp,
      updatedAt: timestamp,
      statusUpdatedAt: timestamp,
      requestExpiryAt: expiryAt,
      flowVersion: policy.flowVersion,
    );

    if (index >= 0) {
      requests[index] = nextRequest;
    } else {
      requests.add(nextRequest);
    }

    return RideRequestMutation(
      ride: _applyLifecycle(
        effectiveRide,
        joinRequests: requests,
        now: timestamp,
      ),
      changed: true,
    );
  }

  static RideRequestMutation cancelPendingRequest(
    RideRequest ride, {
    required String requesterId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final normalized = _normalizeForPendingExpiry(ride, timestamp);
    final effectiveRide = normalized.ride;

    if (requesterId.isEmpty) {
      return RideRequestMutation(
        ride: effectiveRide,
        changed: normalized.changed,
      );
    }

    final requests = List<RideJoinRequest>.from(effectiveRide.joinRequests);
    final index = requests.indexWhere(
      (request) =>
          request.requesterId == requesterId &&
          request.status == RideJoinRequestStatus.pending,
    );
    if (index < 0) {
      return RideRequestMutation(
        ride: effectiveRide,
        changed: normalized.changed,
      );
    }

    requests[index] = requests[index].copyWith(
      status: RideJoinRequestStatus.cancelled,
      updatedAt: timestamp,
      statusUpdatedAt: timestamp,
      resolvedAt: timestamp,
      statusReason: requesterCancelledReason,
      requestClientReasonCode: 'cancelled_by_requester',
      clearRequestExpiryAt: true,
    );

    return RideRequestMutation(
      ride: _applyLifecycle(
        effectiveRide,
        joinRequests: requests,
        now: timestamp,
      ),
      changed: true,
    );
  }

  static RideRequestMutation acceptRequest(
    RideRequest ride, {
    required String requesterId,
    required bool waitForAnotherRider,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final normalized = _normalizeForPendingExpiry(ride, timestamp);
    final effectiveRide = normalized.ride;

    if (_hasReachedCapacity(effectiveRide)) {
      return RideRequestMutation(
        ride: effectiveRide,
        changed: normalized.changed,
      );
    }

    final requests = List<RideJoinRequest>.from(effectiveRide.joinRequests);
    final index = requests.indexWhere(
      (request) =>
          request.requesterId == requesterId &&
          request.status == RideJoinRequestStatus.pending,
    );
    if (index < 0) {
      return RideRequestMutation(
        ride: effectiveRide,
        changed: normalized.changed,
      );
    }

    final acceptedRequest = requests[index].copyWith(
      status: RideJoinRequestStatus.accepted,
      updatedAt: timestamp,
      statusUpdatedAt: timestamp,
      resolvedAt: timestamp,
      clearStatusReason: true,
      requestClientReasonCode: 'accepted_by_host',
      clearRequestExpiryAt: true,
    );
    requests[index] = acceptedRequest;

    final updatedCoRiders = <String>{...effectiveRide.coRiderIds}
      ..add(requesterId);

    final acceptedStops = _upsertAcceptedPickupStop(
      effectiveRide.acceptedPickupStops,
      acceptedRequest,
    );

    final hostCanWait =
        waitForAnotherRider &&
        updatedCoRiders.length < effectiveRide.maxCoRiders;
    if (!hostCanWait) {
      for (
        var requestIndex = 0;
        requestIndex < requests.length;
        requestIndex++
      ) {
        final request = requests[requestIndex];
        if (request.status != RideJoinRequestStatus.pending) {
          continue;
        }
        requests[requestIndex] = request.copyWith(
          status: RideJoinRequestStatus.declined,
          updatedAt: timestamp,
          statusUpdatedAt: timestamp,
          resolvedAt: timestamp,
          statusReason: rideFilledReason,
          requestClientReasonCode: 'ride_filled',
          clearRequestExpiryAt: true,
        );
      }
    }

    return RideRequestMutation(
      ride: _applyLifecycle(
        effectiveRide,
        coRiderIds: updatedCoRiders.toList(growable: false),
        joinRequests: requests,
        acceptedPickupStops: acceptedStops,
        waitForAnotherRiderIntent: waitForAnotherRider,
        now: timestamp,
      ),
      changed: true,
    );
  }

  static RideRequestMutation declineRequest(
    RideRequest ride, {
    required String requesterId,
    String? reason,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final normalized = _normalizeForPendingExpiry(ride, timestamp);
    final effectiveRide = normalized.ride;
    final requests = List<RideJoinRequest>.from(effectiveRide.joinRequests);
    final index = requests.indexWhere(
      (request) =>
          request.requesterId == requesterId &&
          request.status == RideJoinRequestStatus.pending,
    );
    if (index < 0) {
      return RideRequestMutation(
        ride: effectiveRide,
        changed: normalized.changed,
      );
    }

    requests[index] = requests[index].copyWith(
      status: RideJoinRequestStatus.declined,
      updatedAt: timestamp,
      statusUpdatedAt: timestamp,
      resolvedAt: timestamp,
      statusReason: reason ?? hostDeclinedReason,
      requestClientReasonCode: 'declined_by_host',
      clearRequestExpiryAt: true,
    );

    return RideRequestMutation(
      ride: _applyLifecycle(
        effectiveRide,
        joinRequests: requests,
        now: timestamp,
      ),
      changed: true,
    );
  }

  static RideRequestMutation cancelJoinedRide(
    RideRequest ride, {
    required String riderId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final normalized = _normalizeForPendingExpiry(ride, timestamp);
    final effectiveRide = normalized.ride;

    if (riderId.isEmpty || !effectiveRide.coRiderIds.contains(riderId)) {
      return RideRequestMutation(
        ride: effectiveRide,
        changed: normalized.changed,
      );
    }

    final updatedCoRiders = [...effectiveRide.coRiderIds]
      ..removeWhere((value) => value == riderId);
    final updatedRequests = effectiveRide.joinRequests.map((request) {
      if (request.requesterId != riderId) {
        return request;
      }
      return request.copyWith(
        status: RideJoinRequestStatus.cancelled,
        updatedAt: timestamp,
        statusUpdatedAt: timestamp,
        resolvedAt: timestamp,
        statusReason: joinedRiderCancelledReason,
        requestClientReasonCode: 'cancelled_after_join',
        clearRequestExpiryAt: true,
      );
    }).toList();

    return RideRequestMutation(
      ride: _applyLifecycle(
        effectiveRide,
        coRiderIds: updatedCoRiders,
        joinRequests: updatedRequests,
        acceptedPickupStops: effectiveRide.acceptedPickupStops
            .where((pickupStop) => pickupStop.riderId != riderId)
            .toList(),
        now: timestamp,
      ),
      changed: true,
    );
  }

  static RideRequest clearQueueForCancellation(RideRequest ride) {
    return ride.copyWith(
      status: RideStatus.cancelled,
      joinRequests: const [],
      acceptedPickupStops: const [],
      waitForAnotherRider: false,
      readyToProceed: false,
    );
  }

  static RideRequestMutation _normalizeForPendingExpiry(
    RideRequest ride,
    DateTime now,
  ) {
    var changed = false;
    final updatedRequests = ride.joinRequests.map((request) {
      if (!request.isExpiredAt(now)) {
        return request;
      }
      changed = true;
      return request.copyWith(
        status: RideJoinRequestStatus.expired,
        updatedAt: now,
        statusUpdatedAt: now,
        resolvedAt: now,
        statusReason: requestExpiredReason,
        requestClientReasonCode: 'expired',
        clearRequestExpiryAt: true,
      );
    }).toList();

    if (!changed) {
      return RideRequestMutation(ride: ride, changed: false);
    }

    return RideRequestMutation(
      ride: _applyLifecycle(ride, joinRequests: updatedRequests, now: now),
      changed: true,
    );
  }

  static RideRequest _applyLifecycle(
    RideRequest ride, {
    required List<RideJoinRequest> joinRequests,
    required DateTime now,
    List<String>? coRiderIds,
    List<RidePickupStop>? acceptedPickupStops,
    bool? waitForAnotherRiderIntent,
  }) {
    final nextCoRiders = <String>{
      ...(coRiderIds ?? ride.coRiderIds),
    }.toList(growable: false);
    final nextWaitIntent =
        waitForAnotherRiderIntent ?? ride.waitForAnotherRider;
    final lifecycle = _deriveLifecycle(
      ride: ride,
      joinRequests: joinRequests,
      coRiderIds: nextCoRiders,
      waitForAnotherRiderIntent: nextWaitIntent,
    );

    final normalizedRequests = lifecycle.status == RideStatus.matched
        ? _resolvePendingRequestsForMatched(requests: joinRequests, now: now)
        : joinRequests;

    return ride.copyWith(
      joinRequests: normalizedRequests,
      coRiderIds: nextCoRiders,
      acceptedPickupStops: acceptedPickupStops ?? ride.acceptedPickupStops,
      status: lifecycle.status,
      waitForAnotherRider: lifecycle.waitForAnotherRider,
      readyToProceed: lifecycle.readyToProceed,
    );
  }

  static _RideLifecycle _deriveLifecycle({
    required RideRequest ride,
    required List<RideJoinRequest> joinRequests,
    required List<String> coRiderIds,
    required bool waitForAnotherRiderIntent,
  }) {
    final acceptedRiderCount = coRiderIds.length;
    final pendingCount = _pendingRequestCount(joinRequests);
    final hasCapacityForMore = acceptedRiderCount < ride.maxCoRiders;
    final waitForAnotherRider =
        waitForAnotherRiderIntent &&
        acceptedRiderCount > 0 &&
        hasCapacityForMore;
    final readyToProceed = acceptedRiderCount > 0 && !waitForAnotherRider;

    final status = readyToProceed
        ? RideStatus.matched
        : pendingCount > 0
        ? RideStatus.requested
        : RideStatus.pending;

    return _RideLifecycle(
      status: status,
      waitForAnotherRider: waitForAnotherRider,
      readyToProceed: readyToProceed,
    );
  }

  static bool _hasReachedCapacity(RideRequest ride) {
    return <String>{...ride.coRiderIds}.length >= ride.maxCoRiders;
  }

  static int _pendingRequestCount(List<RideJoinRequest> requests) {
    return requests
        .where((request) => request.status == RideJoinRequestStatus.pending)
        .length;
  }

  static List<RideJoinRequest> _resolvePendingRequestsForMatched({
    required List<RideJoinRequest> requests,
    required DateTime now,
  }) {
    return requests.map((request) {
      if (request.status != RideJoinRequestStatus.pending) {
        return request;
      }
      return request.copyWith(
        status: RideJoinRequestStatus.declined,
        updatedAt: now,
        statusUpdatedAt: now,
        resolvedAt: now,
        statusReason: rideFilledReason,
        requestClientReasonCode: 'ride_filled',
        clearRequestExpiryAt: true,
      );
    }).toList();
  }

  static List<RidePickupStop> _upsertAcceptedPickupStop(
    List<RidePickupStop> currentStops,
    RideJoinRequest request,
  ) {
    final latitude = request.requesterPickupLat;
    final longitude = request.requesterPickupLng;
    if (latitude == null || longitude == null) {
      return currentStops;
    }

    final nextStop = RidePickupStop(
      riderId: request.requesterId,
      riderName: request.requesterName,
      latitude: latitude,
      longitude: longitude,
      address: request.requesterPickup,
    );

    return [
      for (final currentStop in currentStops)
        if (currentStop.riderId != nextStop.riderId) currentStop,
      nextStop,
    ];
  }
}

class _RideLifecycle {
  const _RideLifecycle({
    required this.status,
    required this.waitForAnotherRider,
    required this.readyToProceed,
  });

  final RideStatus status;
  final bool waitForAnotherRider;
  final bool readyToProceed;
}
