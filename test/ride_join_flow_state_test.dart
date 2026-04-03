import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/services/ride_join_flow_state.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';

RideRequest _buildRide({
  RideStatus status = RideStatus.pending,
  List<String> coRiderIds = const [],
  List<RideJoinRequest> joinRequests = const [],
  bool waitForAnotherRider = false,
  bool readyToProceed = false,
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
  );
}

void main() {
  group('RideJoinFlowStateResolver', () {
    test('returns startTrip when requester is joined and ride is ready', () {
      final state = RideJoinFlowStateResolver.resolve(
        updatedRide: _buildRide(
          status: RideStatus.matched,
          coRiderIds: const ['rider-1'],
          readyToProceed: true,
        ),
        requesterId: 'rider-1',
        fallbackDeclineMessage: 'declined',
      );

      expect(state.type, RideJoinFlowStateType.startTrip);
    });

    test('returns waitForAnotherRider when joined but not ready', () {
      final state = RideJoinFlowStateResolver.resolve(
        updatedRide: _buildRide(
          status: RideStatus.pending,
          coRiderIds: const ['rider-1'],
          waitForAnotherRider: true,
          readyToProceed: false,
        ),
        requesterId: 'rider-1',
        fallbackDeclineMessage: 'declined',
      );

      expect(state.type, RideJoinFlowStateType.waitForAnotherRider);
    });

    test('returns requestDeclined with reason for terminal request states', () {
      final state = RideJoinFlowStateResolver.resolve(
        updatedRide: _buildRide(
          joinRequests: [
            RideJoinRequest(
              requesterId: 'rider-1',
              status: RideJoinRequestStatus.expired,
              statusReason: 'Request expired.',
              requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
              resolvedAt: DateTime.fromMillisecondsSinceEpoch(2000),
            ),
          ],
        ),
        requesterId: 'rider-1',
        fallbackDeclineMessage: 'declined',
      );

      expect(state.type, RideJoinFlowStateType.requestDeclined);
      expect(state.message, 'Request expired.');
    });

    test('returns requestInactive when requester is no longer tracked', () {
      final state = RideJoinFlowStateResolver.resolve(
        updatedRide: _buildRide(),
        requesterId: 'rider-1',
        fallbackDeclineMessage: 'declined',
      );

      expect(state.type, RideJoinFlowStateType.requestInactive);
    });
  });
}

