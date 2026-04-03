import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/services/ride_queue_policy.dart';
import 'package:shared_cab/core/services/ride_request_queue.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';

RideRequest _buildRide({
  RideStatus status = RideStatus.pending,
  List<String> coRiderIds = const [],
  List<RideJoinRequest> joinRequests = const [],
  bool waitForAnotherRider = false,
  bool readyToProceed = false,
  int maxCoRiders = 3,
}) {
  return RideRequest(
    id: 'ride-1',
    userId: 'host-1',
    userName: 'Host',
    userGender: 'female',
    pickup: const LocationPoint(
      latitude: 13.0000,
      longitude: 80.0000,
      address: 'Pickup',
    ),
    dropoff: const LocationPoint(
      latitude: 13.1000,
      longitude: 80.1000,
      address: 'Dropoff',
    ),
    departureTime: DateTime.fromMillisecondsSinceEpoch(1000),
    status: status,
    createdAt: DateTime.fromMillisecondsSinceEpoch(500),
    coRiderIds: coRiderIds,
    joinRequests: joinRequests,
    waitForAnotherRider: waitForAnotherRider,
    readyToProceed: readyToProceed,
    maxCoRiders: maxCoRiders,
  );
}

RideRequest _queueRequest(
  RideRequest ride, {
  required String requesterId,
  required DateTime now,
}) {
  return RideRequestQueue.enqueueRequest(
    ride,
    requesterId: requesterId,
    requesterName: requesterId,
    requesterGender: 'female',
    requesterPickup: 'Pickup $requesterId',
    requesterDropoff: 'Dropoff $requesterId',
    requesterPickupLat: 13.0100,
    requesterPickupLng: 80.0100,
    now: now,
  ).ride;
}

void main() {
  group('RideRequestQueue', () {
    test('decline followed immediately by a new request reopens the queue', () {
      final initialRide = _queueRequest(
        _buildRide(),
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final declinedRide = RideRequestQueue.declineRequest(
        initialRide,
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(2000),
      ).ride;
      final retriedRide = _queueRequest(
        declinedRide,
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(3000),
      );

      final retriedRequest = retriedRide.joinRequestFor('rider-1');
      expect(retriedRide.status, RideStatus.requested);
      expect(retriedRequest?.status, RideJoinRequestStatus.pending);
      expect(retriedRequest?.resolvedAt, isNull);
    });

    test('cancel then accept race keeps the requester out of the ride', () {
      final queuedRide = _queueRequest(
        _buildRide(),
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final cancelledRide = RideRequestQueue.cancelPendingRequest(
        queuedRide,
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(2000),
      );
      final acceptAfterCancel = RideRequestQueue.acceptRequest(
        cancelledRide.ride,
        requesterId: 'rider-1',
        waitForAnotherRider: false,
        now: DateTime.fromMillisecondsSinceEpoch(3000),
      );

      expect(cancelledRide.changed, isTrue);
      expect(acceptAfterCancel.changed, isFalse);
      expect(acceptAfterCancel.ride.coRiderIds, isEmpty);
      expect(
        acceptAfterCancel.ride.joinRequestFor('rider-1')?.status,
        RideJoinRequestStatus.cancelled,
      );
    });

    test('host accept then requester cancel requires joined cancellation path', () {
      final queuedRide = _queueRequest(
        _buildRide(),
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final acceptedRide = RideRequestQueue.acceptRequest(
        queuedRide,
        requesterId: 'rider-1',
        waitForAnotherRider: true,
        now: DateTime.fromMillisecondsSinceEpoch(2000),
      );
      final cancelPendingAfterAccept = RideRequestQueue.cancelPendingRequest(
        acceptedRide.ride,
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(3000),
      );
      final cancelJoinedRide = RideRequestQueue.cancelJoinedRide(
        acceptedRide.ride,
        riderId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(4000),
      );

      expect(acceptedRide.changed, isTrue);
      expect(acceptedRide.ride.coRiderIds, contains('rider-1'));
      expect(cancelPendingAfterAccept.changed, isFalse);
      expect(cancelJoinedRide.changed, isTrue);
      expect(cancelJoinedRide.ride.coRiderIds, isEmpty);
      expect(
        cancelJoinedRide.ride.joinRequestFor('rider-1')?.status,
        RideJoinRequestStatus.cancelled,
      );
    });

    test('multiple requesters coexist without overwriting each other', () {
      final firstRequest = _queueRequest(
        _buildRide(),
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final secondRequest = _queueRequest(
        firstRequest,
        requesterId: 'rider-2',
        now: DateTime.fromMillisecondsSinceEpoch(2000),
      );
      final acceptedRide = RideRequestQueue.acceptRequest(
        secondRequest,
        requesterId: 'rider-1',
        waitForAnotherRider: true,
        now: DateTime.fromMillisecondsSinceEpoch(3000),
      ).ride;

      expect(secondRequest.joinRequests, hasLength(2));
      expect(acceptedRide.coRiderIds, contains('rider-1'));
      expect(
        acceptedRide.joinRequestFor('rider-1')?.status,
        RideJoinRequestStatus.accepted,
      );
      expect(
        acceptedRide.joinRequestFor('rider-2')?.status,
        RideJoinRequestStatus.pending,
      );
      expect(acceptedRide.status, RideStatus.requested);
    });

    test('matched ride stays ready when one of multiple accepted riders leaves', () {
      final ride = _buildRide(
        status: RideStatus.matched,
        coRiderIds: const ['rider-1', 'rider-2'],
        readyToProceed: true,
        joinRequests: [
          RideJoinRequest(
            requesterId: 'rider-1',
            requesterName: 'rider-1',
            status: RideJoinRequestStatus.accepted,
            requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
            resolvedAt: DateTime.fromMillisecondsSinceEpoch(2000),
          ),
          RideJoinRequest(
            requesterId: 'rider-2',
            requesterName: 'rider-2',
            status: RideJoinRequestStatus.accepted,
            requestedAt: DateTime.fromMillisecondsSinceEpoch(1500),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(2500),
            resolvedAt: DateTime.fromMillisecondsSinceEpoch(2500),
          ),
        ],
      );

      final cancelledRide = RideRequestQueue.cancelJoinedRide(
        ride,
        riderId: 'rider-2',
        now: DateTime.fromMillisecondsSinceEpoch(3000),
      );

      expect(cancelledRide.changed, isTrue);
      expect(cancelledRide.ride.coRiderIds, const ['rider-1']);
      expect(cancelledRide.ride.status, RideStatus.matched);
      expect(cancelledRide.ride.readyToProceed, isTrue);
      expect(
        cancelledRide.ride.joinRequestFor('rider-2')?.status,
        RideJoinRequestStatus.cancelled,
      );
    });

    test('full rides cannot accept another stale pending request', () {
      final ride = _buildRide(
        status: RideStatus.requested,
        coRiderIds: const ['rider-1'],
        maxCoRiders: 1,
        joinRequests: [
          RideJoinRequest(
            requesterId: 'rider-2',
            requesterName: 'rider-2',
            status: RideJoinRequestStatus.pending,
            requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
          ),
        ],
      );

      final acceptedRide = RideRequestQueue.acceptRequest(
        ride,
        requesterId: 'rider-2',
        waitForAnotherRider: false,
        now: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      expect(acceptedRide.changed, isFalse);
      expect(acceptedRide.ride.coRiderIds, const ['rider-1']);
      expect(
        acceptedRide.ride.joinRequestFor('rider-2')?.status,
        RideJoinRequestStatus.pending,
      );
    });

    test('expired pending requests are marked and do not block new requests', () {
      final firstRequestTime = DateTime.fromMillisecondsSinceEpoch(1000);
      final secondRequestTime = firstRequestTime.add(const Duration(minutes: 16));
      final firstQueuedRide = _queueRequest(
        _buildRide(),
        requesterId: 'rider-1',
        now: firstRequestTime,
      );

      final secondQueuedRide = RideRequestQueue.enqueueRequest(
        firstQueuedRide,
        requesterId: 'rider-2',
        requesterName: 'rider-2',
        requesterGender: 'female',
        requesterPickup: 'Pickup rider-2',
        requesterDropoff: 'Dropoff rider-2',
        requesterPickupLat: 13.0200,
        requesterPickupLng: 80.0200,
        now: secondRequestTime,
      ).ride;

      expect(secondQueuedRide.status, RideStatus.requested);
      expect(
        secondQueuedRide.joinRequestFor('rider-1')?.status,
        RideJoinRequestStatus.expired,
      );
      expect(
        secondQueuedRide.joinRequestFor('rider-2')?.status,
        RideJoinRequestStatus.pending,
      );
    });

    test('policy can tighten pending queue limit', () {
      final ride = _buildRide();
      final queued = _queueRequest(
        ride,
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      expect(
        () => RideRequestQueue.enqueueRequest(
          queued,
          requesterId: 'rider-2',
          requesterName: 'rider-2',
          requesterGender: 'female',
          requesterPickup: 'Pickup rider-2',
          requesterDropoff: 'Dropoff rider-2',
          requesterPickupLat: 13.0200,
          requesterPickupLng: 80.0200,
          now: DateTime.fromMillisecondsSinceEpoch(1100),
          policy: const RideQueuePolicy(maxPendingRequests: 1),
        ),
        throwsStateError,
      );
    });

    test('accepted rider remains matched even if stale pending requests exist', () {
      final ride = _buildRide(
        status: RideStatus.requested,
        coRiderIds: const ['rider-1'],
        waitForAnotherRider: false,
        joinRequests: [
          RideJoinRequest(
            requesterId: 'rider-1',
            requesterName: 'rider-1',
            status: RideJoinRequestStatus.accepted,
            requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
            resolvedAt: DateTime.fromMillisecondsSinceEpoch(1000),
          ),
          RideJoinRequest(
            requesterId: 'rider-2',
            requesterName: 'rider-2',
            status: RideJoinRequestStatus.pending,
            requestedAt: DateTime.fromMillisecondsSinceEpoch(1200),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(1200),
          ),
        ],
      );

      final cancelledOtherPending = RideRequestQueue.cancelPendingRequest(
        ride,
        requesterId: 'rider-2',
        now: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      expect(cancelledOtherPending.changed, isTrue);
      expect(cancelledOtherPending.ride.status, RideStatus.matched);
      expect(cancelledOtherPending.ride.readyToProceed, isTrue);
      expect(cancelledOtherPending.ride.waitForAnotherRider, isFalse);
    });

    test('matched lifecycle auto-resolves stale pending requests', () {
      final queuedRide = _queueRequest(
        _buildRide(),
        requesterId: 'rider-1',
        now: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final withSecondPending = _queueRequest(
        queuedRide,
        requesterId: 'rider-2',
        now: DateTime.fromMillisecondsSinceEpoch(1200),
      );
      final acceptedRide = RideRequestQueue.acceptRequest(
        withSecondPending,
        requesterId: 'rider-1',
        waitForAnotherRider: false,
        now: DateTime.fromMillisecondsSinceEpoch(2000),
      ).ride;

      expect(acceptedRide.status, RideStatus.matched);
      expect(
        acceptedRide.joinRequestFor('rider-2')?.status,
        RideJoinRequestStatus.declined,
      );
      expect(
        acceptedRide.joinRequestFor('rider-2')?.statusReason,
        RideRequestQueue.rideFilledReason,
      );
    });
  });
}
