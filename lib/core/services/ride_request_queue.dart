import 'package:shared_cab/models/ride_request_model.dart';

class RideRequestMutation {
  const RideRequestMutation({
    required this.ride,
    required this.changed,
  });

  final RideRequest ride;
  final bool changed;
}

class RideRequestQueue {
  RideRequestQueue._();

  static const String requesterCancelledReason = 'Requester cancelled the ride.';
  static const String hostDeclinedReason = 'Host declined the ride request.';
  static const String rideFilledReason = 'Ride is no longer available.';
  static const String joinedRiderCancelledReason =
      'Joined rider left before the trip started.';

  static bool isDiscoverable(RideRequest ride) {
    return ride.status == RideStatus.pending || ride.status == RideStatus.requested;
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
  }) {
    if (requesterId.isEmpty) {
      throw StateError('Requester id is required.');
    }
    if (requesterId == ride.userId) {
      throw StateError('You cannot request your own ride.');
    }
    if (!isDiscoverable(ride)) {
      throw StateError('This ride is no longer accepting requests.');
    }
    if (_hasReachedCapacity(ride)) {
      throw StateError('This ride is already full.');
    }
    if (ride.coRiderIds.contains(requesterId)) {
      throw StateError('You already joined this ride.');
    }

    final timestamp = now ?? DateTime.now();
    final requests = List<RideJoinRequest>.from(ride.joinRequests);
    final index = requests.indexWhere(
      (request) => request.requesterId == requesterId,
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
    );

    if (index >= 0) {
      requests[index] = nextRequest;
    } else {
      requests.add(nextRequest);
    }

    return RideRequestMutation(
      ride: _copyWithQueue(
        ride,
        joinRequests: requests,
        status: _resolveDiscoverableStatus(requests),
        readyToProceed: false,
      ),
      changed: true,
    );
  }

  static RideRequestMutation cancelPendingRequest(
    RideRequest ride, {
    required String requesterId,
    DateTime? now,
  }) {
    if (requesterId.isEmpty) {
      return RideRequestMutation(ride: ride, changed: false);
    }

    final requests = List<RideJoinRequest>.from(ride.joinRequests);
    final index = requests.indexWhere(
      (request) =>
          request.requesterId == requesterId &&
          request.status == RideJoinRequestStatus.pending,
    );
    if (index < 0) {
      return RideRequestMutation(ride: ride, changed: false);
    }

    final timestamp = now ?? DateTime.now();
    requests[index] = requests[index].copyWith(
      status: RideJoinRequestStatus.cancelled,
      updatedAt: timestamp,
      resolvedAt: timestamp,
      statusReason: requesterCancelledReason,
    );

    return RideRequestMutation(
      ride: _copyWithQueue(
        ride,
        joinRequests: requests,
        status: _statusAfterPendingQueueChange(
          ride: ride,
          requests: requests,
        ),
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
    if (_hasReachedCapacity(ride)) {
      return RideRequestMutation(ride: ride, changed: false);
    }

    final requests = List<RideJoinRequest>.from(ride.joinRequests);
    final index = requests.indexWhere(
      (request) =>
          request.requesterId == requesterId &&
          request.status == RideJoinRequestStatus.pending,
    );
    if (index < 0) {
      return RideRequestMutation(ride: ride, changed: false);
    }

    final timestamp = now ?? DateTime.now();
    final acceptedRequest = requests[index].copyWith(
      status: RideJoinRequestStatus.accepted,
      updatedAt: timestamp,
      resolvedAt: timestamp,
      clearStatusReason: true,
    );
    requests[index] = acceptedRequest;

    final updatedCoRiders = [...ride.coRiderIds];
    if (!updatedCoRiders.contains(requesterId)) {
      updatedCoRiders.add(requesterId);
    }

    final acceptedStops = _upsertAcceptedPickupStop(
      ride.acceptedPickupStops,
      acceptedRequest,
    );

    final canWaitForAnotherRider =
        waitForAnotherRider && updatedCoRiders.toSet().length < ride.maxCoRiders;

    if (!canWaitForAnotherRider) {
      for (var index = 0; index < requests.length; index++) {
        final request = requests[index];
        if (request.status != RideJoinRequestStatus.pending) {
          continue;
        }
        requests[index] = request.copyWith(
          status: RideJoinRequestStatus.declined,
          updatedAt: timestamp,
          resolvedAt: timestamp,
          statusReason: rideFilledReason,
        );
      }
    }

    final nextStatus = canWaitForAnotherRider
        ? _resolveDiscoverableStatus(requests)
        : RideStatus.matched;

    return RideRequestMutation(
      ride: ride.copyWith(
        coRiderIds: updatedCoRiders,
        joinRequests: requests,
        acceptedPickupStops: acceptedStops,
        status: nextStatus,
        waitForAnotherRider: canWaitForAnotherRider,
        readyToProceed: !canWaitForAnotherRider,
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
    final requests = List<RideJoinRequest>.from(ride.joinRequests);
    final index = requests.indexWhere(
      (request) =>
          request.requesterId == requesterId &&
          request.status == RideJoinRequestStatus.pending,
    );
    if (index < 0) {
      return RideRequestMutation(ride: ride, changed: false);
    }

    final timestamp = now ?? DateTime.now();
    requests[index] = requests[index].copyWith(
      status: RideJoinRequestStatus.declined,
      updatedAt: timestamp,
      resolvedAt: timestamp,
      statusReason: reason ?? hostDeclinedReason,
    );

    return RideRequestMutation(
      ride: _copyWithQueue(
        ride,
        joinRequests: requests,
        status: _statusAfterPendingQueueChange(
          ride: ride,
          requests: requests,
        ),
      ),
      changed: true,
    );
  }

  static RideRequestMutation cancelJoinedRide(
    RideRequest ride, {
    required String riderId,
    DateTime? now,
  }) {
    if (riderId.isEmpty || !ride.coRiderIds.contains(riderId)) {
      return RideRequestMutation(ride: ride, changed: false);
    }

    final timestamp = now ?? DateTime.now();
    final updatedCoRiders = [...ride.coRiderIds]
      ..removeWhere((value) => value == riderId);
    final updatedRequests = ride.joinRequests
        .map((request) {
          if (request.requesterId != riderId) {
            return request;
          }
          return request.copyWith(
            status: RideJoinRequestStatus.cancelled,
            updatedAt: timestamp,
            resolvedAt: timestamp,
            statusReason: joinedRiderCancelledReason,
          );
        })
        .toList();

    final pendingRequests = _pendingRequestCount(updatedRequests);
    final acceptedRiderCount = updatedCoRiders.toSet().length;
    final hasCapacityForMore = updatedCoRiders.toSet().length < ride.maxCoRiders;
    final shouldRemainWaiting =
        ride.waitForAnotherRider && hasCapacityForMore && acceptedRiderCount > 0;

    final shouldStayMatched =
        !ride.waitForAnotherRider && acceptedRiderCount > 0;

    final nextStatus = pendingRequests > 0
        ? RideStatus.requested
        : shouldStayMatched
        ? RideStatus.matched
        : shouldRemainWaiting
        ? RideStatus.pending
        : RideStatus.pending;

    return RideRequestMutation(
      ride: ride.copyWith(
        coRiderIds: updatedCoRiders,
        joinRequests: updatedRequests,
        acceptedPickupStops: ride.acceptedPickupStops
            .where((pickupStop) => pickupStop.riderId != riderId)
            .toList(),
        status: nextStatus,
        waitForAnotherRider: shouldRemainWaiting,
        readyToProceed: shouldStayMatched,
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

  static bool _hasReachedCapacity(RideRequest ride) {
    return ride.coRiderIds.toSet().length >= ride.maxCoRiders;
  }

  static RideRequest _copyWithQueue(
    RideRequest ride, {
    required List<RideJoinRequest> joinRequests,
    required RideStatus status,
    bool? readyToProceed,
  }) {
    return ride.copyWith(
      joinRequests: joinRequests,
      status: status,
      readyToProceed: readyToProceed,
      waitForAnotherRider: status == RideStatus.matched
          ? false
          : ride.waitForAnotherRider,
    );
  }

  static int _pendingRequestCount(List<RideJoinRequest> requests) {
    return requests
        .where((request) => request.status == RideJoinRequestStatus.pending)
        .length;
  }

  static RideStatus _resolveDiscoverableStatus(List<RideJoinRequest> requests) {
    return _pendingRequestCount(requests) > 0
        ? RideStatus.requested
        : RideStatus.pending;
  }

  static RideStatus _statusAfterPendingQueueChange({
    required RideRequest ride,
    required List<RideJoinRequest> requests,
  }) {
    final pendingCount = _pendingRequestCount(requests);
    if (pendingCount > 0) {
      return RideStatus.requested;
    }
    if (ride.waitForAnotherRider && ride.coRiderIds.isNotEmpty) {
      return RideStatus.pending;
    }
    return RideStatus.pending;
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
