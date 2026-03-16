import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/session/ride_session_controller.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/ride_session_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

class _RideSessionHarness {
  const _RideSessionHarness(this.store);

  final RideSessionStore store;

  Trip startDirectTrip({
    required RideRequest ride,
    required String riderId,
    double? distanceKm,
    DateTime? startTime,
  }) {
    return RideSessionController.startDirectTrip(
      store,
      ride: ride,
      riderId: riderId,
      distanceKm: distanceKm,
      startTime: startTime,
    );
  }

  Trip startSharedTrip({
    required RideRequest ride,
    DateTime? startTime,
    double? distanceKm,
  }) {
    return RideSessionController.startSharedTrip(
      store,
      ride: ride,
      startTime: startTime,
      distanceKm: distanceKm,
    );
  }

  RideSession? markTripInProgress({DateTime? occurredAt}) {
    return RideSessionController.markTripInProgress(
      store,
      occurredAt: occurredAt,
    );
  }

  RideSession? markTripArrived({DateTime? occurredAt}) {
    return RideSessionController.markTripArrived(store, occurredAt: occurredAt);
  }

  RideSession? triggerPanic({DateTime? occurredAt}) {
    return RideSessionController.triggerPanic(store, occurredAt: occurredAt);
  }

  bool confirmSafeArrival({
    required String submittedPin,
    DateTime? occurredAt,
  }) {
    return RideSessionController.confirmSafeArrival(
      store,
      submittedPin: submittedPin,
      occurredAt: occurredAt,
    );
  }

  void archiveActiveSession({DateTime? occurredAt}) {
    RideSessionController.archiveActiveSession(store, occurredAt: occurredAt);
  }

  void closeActiveSession({bool clearRideContext = false}) {
    RideSessionController.closeActiveSession(
      store,
      clearRideContext: clearRideContext,
    );
  }
}

RideRequest _buildRide({
  RideStatus status = RideStatus.pending,
  List<String> coRiderIds = const [],
  String safeArrivalPin = '2468',
}) {
  return RideRequest(
    id: 'ride-1',
    userId: 'host-1',
    userName: 'Host',
    userGender: 'male',
    pickup: const LocationPoint(
      latitude: 13.0000,
      longitude: 80.0000,
      address: 'Pickup',
    ),
    dropoff: const LocationPoint(
      latitude: 13.1000,
      longitude: 80.0000,
      address: 'Dropoff',
    ),
    departureTime: DateTime.fromMillisecondsSinceEpoch(1000),
    status: status,
    createdAt: DateTime.fromMillisecondsSinceEpoch(900),
    coRiderIds: coRiderIds,
    safeArrivalPin: safeArrivalPin,
  );
}

void main() {
  group('RideSessionController', () {
    test('startDirectTrip writes canonical ride, trip, and session state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final harness = _RideSessionHarness(
        RideSessionStore.container(container),
      );

      final trip = harness.startDirectTrip(
        ride: _buildRide(safeArrivalPin: ''),
        riderId: 'host-1',
        distanceKm: 12,
        startTime: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      final activeRide = container.read(currentRideRequestProvider);
      final session = container.read(activeRideSessionProvider);

      expect(trip.status, TripStatus.waitingForPickup);
      expect(activeRide?.status, RideStatus.active);
      expect(activeRide?.readyToProceed, isTrue);
      expect(
        RegExp(r'^\d{4}$').hasMatch(activeRide?.safeArrivalPin ?? ''),
        isTrue,
      );
      expect(session?.rideId, activeRide?.id);
      expect(session?.tripId, trip.id);
      expect(session?.tripStatus, TripStatus.waitingForPickup);
      expect(session?.events.map((event) => event.type).toList(), [
        RideSessionEventType.sessionStarted,
      ]);
    });

    test(
      'trip progress transition is idempotent and updates ride status once',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final harness = _RideSessionHarness(
          RideSessionStore.container(container),
        );

        harness.startSharedTrip(
          ride: _buildRide(
            status: RideStatus.matched,
            coRiderIds: const ['rider-2'],
          ),
          startTime: DateTime.fromMillisecondsSinceEpoch(3000),
        );

        harness.markTripInProgress(
          occurredAt: DateTime.fromMillisecondsSinceEpoch(4000),
        );
        harness.markTripInProgress(
          occurredAt: DateTime.fromMillisecondsSinceEpoch(5000),
        );

        final activeRide = container.read(currentRideRequestProvider);
        final activeTrip = container.read(activeTripProvider);
        final session = container.read(activeRideSessionProvider)!;
        final inProgressEvents = session.events
            .where((event) => event.type == RideSessionEventType.tripInProgress)
            .toList();

        expect(activeRide?.status, RideStatus.active);
        expect(activeTrip?.status, TripStatus.inProgress);
        expect(inProgressEvents, hasLength(1));
        expect(session.events.map((event) => event.type).toList(), [
          RideSessionEventType.sessionStarted,
          RideSessionEventType.tripInProgress,
        ]);
      },
    );

    test(
      'panic, arrival, and safe-arrival archive one authoritative session',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final harness = _RideSessionHarness(
          RideSessionStore.container(container),
        );

        final trip = harness.startSharedTrip(
          ride: _buildRide(
            status: RideStatus.matched,
            coRiderIds: const ['rider-2', 'rider-3'],
          ),
          startTime: DateTime.fromMillisecondsSinceEpoch(3000),
        );

        harness.triggerPanic(
          occurredAt: DateTime.fromMillisecondsSinceEpoch(3500),
        );
        harness.markTripArrived(
          occurredAt: DateTime.fromMillisecondsSinceEpoch(4000),
        );
        final confirmed = harness.confirmSafeArrival(
          submittedPin: trip.safeArrivalPin!,
          occurredAt: DateTime.fromMillisecondsSinceEpoch(4500),
        );

        final activeTrip = container.read(activeTripProvider);
        final activeSession = container.read(activeRideSessionProvider)!;
        final archivedSessions = container.read(rideSessionHistoryProvider);
        final rideHistory = container.read(rideHistoryProvider);

        expect(confirmed, isTrue);
        expect(activeTrip?.status, TripStatus.completed);
        expect(activeTrip?.isPinConfirmed, isTrue);
        expect(activeSession.panicTriggered, isTrue);
        expect(activeSession.isArchived, isTrue);
        expect(activeSession.events.map((event) => event.type).toList(), [
          RideSessionEventType.sessionStarted,
          RideSessionEventType.emergencyTriggered,
          RideSessionEventType.destinationArrived,
          RideSessionEventType.safeArrivalConfirmed,
          RideSessionEventType.sessionArchived,
        ]);
        expect(archivedSessions, hasLength(1));
        expect(rideHistory, hasLength(1));
        expect(archivedSessions.single.tripId, trip.id);
      },
    );

    test(
      'controller recovers a missing session from legacy active trip state',
      () {
        final trip = Trip(
          id: 'trip-legacy',
          matchId: 'shared_ride-legacy',
          riderIds: const ['host-1', 'rider-2'],
          startTime: DateTime.fromMillisecondsSinceEpoch(1000),
          safeArrivalPin: '1357',
          isNightTrip: true,
        );
        final container = ProviderContainer(
          overrides: [activeTripProvider.overrideWith((ref) => trip)],
        );
        addTearDown(container.dispose);
        final harness = _RideSessionHarness(
          RideSessionStore.container(container),
        );

        final confirmed = harness.confirmSafeArrival(
          submittedPin: '1357',
          occurredAt: DateTime.fromMillisecondsSinceEpoch(2000),
        );

        final recoveredSession = container.read(activeRideSessionProvider)!;
        expect(confirmed, isTrue);
        expect(recoveredSession.rideId, 'ride-legacy');
        expect(recoveredSession.events.first.summary, contains('recovered'));
        expect(container.read(rideSessionHistoryProvider), hasLength(1));
      },
    );

    test(
      'archive and close keeps history while clearing active lifecycle state',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final harness = _RideSessionHarness(
          RideSessionStore.container(container),
        );

        harness.startDirectTrip(
          ride: _buildRide(),
          riderId: 'host-1',
          startTime: DateTime.fromMillisecondsSinceEpoch(1000),
        );
        harness.archiveActiveSession(
          occurredAt: DateTime.fromMillisecondsSinceEpoch(2000),
        );
        harness.closeActiveSession(clearRideContext: true);

        expect(container.read(activeTripProvider), isNull);
        expect(container.read(activeRideSessionProvider), isNull);
        expect(container.read(currentRideRequestProvider), isNull);
        expect(container.read(rideHistoryProvider), hasLength(1));
        expect(container.read(rideSessionHistoryProvider), hasLength(1));
        expect(container.read(panicModeProvider), isFalse);
      },
    );
  });
}
