import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/services/ride_join_flow_coordinator.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/user_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

class _FakeRideJoinFlowGateway extends RideJoinFlowGateway {
  final StreamController<RideRequest?> controller =
      StreamController<RideRequest?>.broadcast();

  bool cancelPendingShouldSucceed = true;
  bool cancelJoinedShouldSucceed = true;
  int cancelPendingCalls = 0;
  int cancelJoinedCalls = 0;

  @override
  Future<void> requestToJoin({
    required String rideId,
    required String requesterId,
    required String requesterName,
    required String requesterGender,
    required String requesterPickup,
    required String requesterDropoff,
    required double? requesterPickupLat,
    required double? requesterPickupLng,
  }) async {}

  @override
  Future<bool> cancelPendingRequest(
    String rideId, {
    required String requesterId,
  }) async {
    cancelPendingCalls += 1;
    return cancelPendingShouldSucceed;
  }

  @override
  Future<bool> cancelJoinedRide(String rideId) async {
    cancelJoinedCalls += 1;
    return cancelJoinedShouldSucceed;
  }

  @override
  Stream<RideRequest?> rideStream(String rideId) {
    return controller.stream;
  }

  Future<void> dispose() async {
    await controller.close();
  }
}

class _JoinFlowHarness extends ConsumerWidget {
  const _JoinFlowHarness({required this.coordinator, required this.hostRide});

  final RideJoinFlowCoordinator coordinator;
  final RideRequest hostRide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              coordinator.start(context: context, ref: ref, hostRide: hostRide),
          child: const Text('Share Ride'),
        ),
      ),
    );
  }
}

RideRequest _buildRide({
  required String requesterId,
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

RideRequest _buildRequestedRide() {
  return _buildRide(
    requesterId: 'rider-1',
    status: RideStatus.pending,
    joinRequests: [
      RideJoinRequest(
        requesterId: 'rider-1',
        requesterName: 'Rider One',
        status: RideJoinRequestStatus.pending,
        requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      ),
    ],
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required _FakeRideJoinFlowGateway gateway,
  required RideRequest hostRide,
}) async {
  final coordinator = RideJoinFlowCoordinator(gateway: gateway);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            _JoinFlowHarness(coordinator: coordinator, hostRide: hostRide),
      ),
      GoRoute(
        path: '/trip/:tripId',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Trip Route'))),
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      currentUserOverrideProvider.overrideWith(
        (ref) => const User(
          id: 'rider-1',
          name: 'Rider One',
          phone: '123',
          email: 'rider@example.com',
          gender: 'female',
        ),
      ),
      currentRideRequestProvider.overrideWith(
        (ref) => _buildRide(requesterId: 'rider-1'),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(gateway.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RideJoinFlowCoordinator', () {
    testWidgets('send -> wait -> accept navigates into the trip flow', (
      tester,
    ) async {
      final gateway = _FakeRideJoinFlowGateway();
      await _pumpHarness(
        tester,
        gateway: gateway,
        hostRide: _buildRide(requesterId: 'rider-1'),
      );

      await tester.tap(find.text('Share Ride'));
      await tester.pump();
      gateway.controller.add(_buildRequestedRide());
      await tester.pump();
      expect(find.text('Waiting for approval'), findsOneWidget);

      gateway.controller.add(
        _buildRide(
          requesterId: 'rider-1',
          status: RideStatus.matched,
          coRiderIds: const ['rider-1'],
          readyToProceed: true,
          joinRequests: [
            RideJoinRequest(
              requesterId: 'rider-1',
              requesterName: 'Rider One',
              status: RideJoinRequestStatus.accepted,
              requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
              resolvedAt: DateTime.fromMillisecondsSinceEpoch(2000),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip Route'), findsOneWidget);
    });

    testWidgets('send -> wait -> decline surfaces the host decision', (
      tester,
    ) async {
      final gateway = _FakeRideJoinFlowGateway();
      await _pumpHarness(
        tester,
        gateway: gateway,
        hostRide: _buildRide(requesterId: 'rider-1'),
      );

      await tester.tap(find.text('Share Ride'));
      await tester.pump();
      gateway.controller.add(_buildRequestedRide());
      await tester.pump();

      gateway.controller.add(
        _buildRide(
          requesterId: 'rider-1',
          status: RideStatus.pending,
          joinRequests: [
            RideJoinRequest(
              requesterId: 'rider-1',
              requesterName: 'Rider One',
              status: RideJoinRequestStatus.declined,
              requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
              resolvedAt: DateTime.fromMillisecondsSinceEpoch(2000),
              statusReason: 'Host declined the ride request.',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Host declined the ride request.'), findsOneWidget);
    });

    testWidgets('send -> wait -> expired request closes waiting dialog', (
      tester,
    ) async {
      final gateway = _FakeRideJoinFlowGateway();
      await _pumpHarness(
        tester,
        gateway: gateway,
        hostRide: _buildRide(requesterId: 'rider-1'),
      );

      await tester.tap(find.text('Share Ride'));
      await tester.pump();
      gateway.controller.add(_buildRequestedRide());
      await tester.pump();

      gateway.controller.add(
        _buildRide(
          requesterId: 'rider-1',
          status: RideStatus.pending,
          joinRequests: [
            RideJoinRequest(
              requesterId: 'rider-1',
              requesterName: 'Rider One',
              status: RideJoinRequestStatus.expired,
              requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
              resolvedAt: DateTime.fromMillisecondsSinceEpoch(2000),
              statusReason: 'Request expired.',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Request expired.'), findsOneWidget);
      expect(find.text('Waiting for approval'), findsNothing);
    });

    testWidgets('send -> wait -> cancel uses the shared cancellation path', (
      tester,
    ) async {
      final gateway = _FakeRideJoinFlowGateway();
      await _pumpHarness(
        tester,
        gateway: gateway,
        hostRide: _buildRide(requesterId: 'rider-1'),
      );

      await tester.tap(find.text('Share Ride'));
      await tester.pump();
      gateway.controller.add(_buildRequestedRide());
      await tester.pump();

      await tester.tap(find.text('Cancel Request'));
      await tester.pumpAndSettle();

      expect(gateway.cancelPendingCalls, 1);
      expect(find.text('Waiting for approval'), findsNothing);
    });

    testWidgets('wait-for-another-rider cancel uses joined-ride cancellation', (
      tester,
    ) async {
      final gateway = _FakeRideJoinFlowGateway();
      await _pumpHarness(
        tester,
        gateway: gateway,
        hostRide: _buildRide(requesterId: 'rider-1'),
      );

      await tester.tap(find.text('Share Ride'));
      await tester.pump();
      gateway.controller.add(_buildRequestedRide());
      await tester.pump();

      gateway.controller.add(
        _buildRide(
          requesterId: 'rider-1',
          status: RideStatus.pending,
          coRiderIds: const ['rider-1'],
          waitForAnotherRider: true,
          joinRequests: [
            RideJoinRequest(
              requesterId: 'rider-1',
              requesterName: 'Rider One',
              status: RideJoinRequestStatus.accepted,
              requestedAt: DateTime.fromMillisecondsSinceEpoch(1000),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
              resolvedAt: DateTime.fromMillisecondsSinceEpoch(2000),
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Waiting for another rider'), findsOneWidget);

      await tester.tap(find.text('Cancel Ride'));
      await tester.pumpAndSettle();

      expect(gateway.cancelJoinedCalls, 1);
    });
  });
}
