// SPEC: Ride Session Engine
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WHAT IT DOES:
//   Centralizes active ride lifecycle mutations so every trip start, progress,
//   panic, arrival, and archival step updates one canonical session state.
//
// DATA OBJECTS:
//   RideSession - authoritative local lifecycle snapshot for one active trip
//   RideSessionEvent - audit trail entry describing a user-visible milestone
//
// OPERATIONS:
//   startDirectTrip/startSharedTrip: RideRequest -> Trip and active session
//   markTripInProgress/markTripArrived/triggerPanic: current state -> next state
//   confirmSafeArrival/archiveActiveSession/closeActiveSession: active state ->
//   completed or cleared state with durable history
//
// EDGE CASES HANDLED:
//   • repeated lifecycle calls are idempotent and do not duplicate events
//   • session state can be recovered from an active Trip even if no session was
//     created earlier (for tests, deep links, or legacy flows)
//   • archival dedupes by trip id so completion flows can safely call it twice
//
// ASSUMPTIONS MADE:
//   • local Riverpod state remains the canonical source inside the app session
//   • existing screens can keep reading activeTrip/currentRideRequest while
//     writes are routed through this controller
//
// DONE WHEN:
//   all ride lifecycle mutations go through one controller, archived session
//   history is preserved, and tests cover direct/shared, progress, panic,
//   arrival, safe-arrival, and cleanup transitions.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_cab/core/utils/ride_trip_utils.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/ride_session_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

class RideSessionStore {
  RideSessionStore._({
    required T Function<T>(ProviderListenable<T> provider) reader,
    required void Function<T>(StateProvider<T> provider, T value) writer,
  }) : _reader = reader,
       _writer = writer;

  factory RideSessionStore.widget(WidgetRef ref) {
    return RideSessionStore._(
      reader: ref.read,
      writer: <T>(provider, value) => ref.read(provider.notifier).state = value,
    );
  }

  factory RideSessionStore.container(ProviderContainer container) {
    return RideSessionStore._(
      reader: container.read,
      writer: <T>(provider, value) =>
          container.read(provider.notifier).state = value,
    );
  }

  final T Function<T>(ProviderListenable<T> provider) _reader;
  final void Function<T>(StateProvider<T> provider, T value) _writer;

  T read<T>(ProviderListenable<T> provider) => _reader(provider);

  void write<T>(StateProvider<T> provider, T value) => _writer(provider, value);
}

class RideSessionController {
  RideSessionController._();

  static Trip startDirectTrip(
    RideSessionStore store, {
    required RideRequest ride,
    required String riderId,
    double? distanceKm,
    DateTime? startTime,
  }) {
    final canonicalRide = RideTripUtils.prepareRideForPublication(
      ride,
      directRide: true,
    );
    final trip = RideTripUtils.buildDirectTripFromRide(
      ride: canonicalRide,
      riderId: riderId,
      distanceKm: distanceKm,
      startTime: startTime,
    );
    final session = RideSession(
      rideId: canonicalRide.id,
      tripId: trip.id,
      riderIds: trip.riderIds,
      rideStatus: canonicalRide.status,
      tripStatus: trip.status,
      safeArrivalPin: trip.safeArrivalPin ?? '',
      startedAt: trip.startTime,
      events: [
        RideSessionEvent(
          type: RideSessionEventType.sessionStarted,
          occurredAt: trip.startTime,
          summary: 'Direct ride session started.',
        ),
      ],
    );

    _setActiveState(
      store,
      ride: canonicalRide,
      trip: trip,
      session: session,
      resetPanic: true,
    );
    return trip;
  }

  static Trip startSharedTrip(
    RideSessionStore store, {
    required RideRequest ride,
    DateTime? startTime,
    double? distanceKm,
  }) {
    final canonicalRide = ride.copyWith(
      status: RideStatus.matched,
      readyToProceed: true,
      safeArrivalPin: RideTripUtils.resolveRideSafeArrivalPin(ride),
    );
    final trip = RideTripUtils.buildSharedTripFromRide(
      ride: canonicalRide,
      startTime: startTime,
      distanceKm: distanceKm,
    );
    final session = RideSession(
      rideId: canonicalRide.id,
      tripId: trip.id,
      riderIds: trip.riderIds,
      rideStatus: canonicalRide.status,
      tripStatus: trip.status,
      safeArrivalPin: trip.safeArrivalPin ?? '',
      startedAt: trip.startTime,
      events: [
        RideSessionEvent(
          type: RideSessionEventType.sessionStarted,
          occurredAt: trip.startTime,
          summary:
              'Shared ride session started with ${trip.participantCount} riders.',
        ),
      ],
    );

    _setActiveState(
      store,
      ride: canonicalRide,
      trip: trip,
      session: session,
      resetPanic: true,
    );
    return trip;
  }

  static RideSession? markTripInProgress(
    RideSessionStore store, {
    DateTime? occurredAt,
    String summary = 'Cab reached pickup and the trip started.',
  }) {
    return _transition(
      store,
      nextTripStatus: TripStatus.inProgress,
      nextRideStatus: RideStatus.active,
      eventType: RideSessionEventType.tripInProgress,
      summary: summary,
      occurredAt: occurredAt,
    );
  }

  static RideSession? markTripArrived(
    RideSessionStore store, {
    DateTime? occurredAt,
    String summary = 'Cab arrived at the destination.',
  }) {
    return _transition(
      store,
      nextTripStatus: TripStatus.arrivedDestination,
      nextRideStatus: RideStatus.completed,
      eventType: RideSessionEventType.destinationArrived,
      summary: summary,
      occurredAt: occurredAt,
      setTripEndTime: true,
    );
  }

  static RideSession? triggerPanic(
    RideSessionStore store, {
    DateTime? occurredAt,
    String summary = 'Emergency mode triggered for this trip.',
  }) {
    final trip = store.read(activeTripProvider);
    if (trip == null || trip.panicTriggered) {
      return store.read(activeRideSessionProvider);
    }

    final ride = store.read(currentRideRequestProvider);
    final session = _hydrateSession(store);
    final resolvedAt = occurredAt ?? DateTime.now();
    final updatedTrip = trip.copyWith(panicTriggered: true);
    final updatedSession = _appendEvent(
      session.copyWith(
        riderIds: updatedTrip.riderIds,
        tripStatus: updatedTrip.status,
        rideStatus: ride?.status ?? session.rideStatus,
        safeArrivalPin: updatedTrip.safeArrivalPin ?? session.safeArrivalPin,
        panicTriggered: true,
      ),
      RideSessionEvent(
        type: RideSessionEventType.emergencyTriggered,
        occurredAt: resolvedAt,
        summary: summary,
      ),
    );

    store.write(activeTripProvider, updatedTrip);
    store.write(activeRideSessionProvider, updatedSession);
    store.write(panicModeProvider, true);
    return updatedSession;
  }

  static bool confirmSafeArrival(
    RideSessionStore store, {
    required String submittedPin,
    DateTime? occurredAt,
  }) {
    final trip = store.read(activeTripProvider);
    if (trip == null) return false;

    final expectedPin = trip.safeArrivalPin ?? '';
    final normalizedPin = submittedPin.trim();
    if (expectedPin.isEmpty || normalizedPin != expectedPin) {
      return false;
    }

    final resolvedAt = occurredAt ?? DateTime.now();
    final ride = store.read(currentRideRequestProvider);
    final updatedTrip = trip.copyWith(
      isPinConfirmed: true,
      status: TripStatus.completed,
      endTime: resolvedAt,
    );
    final session = _appendEvent(
      _hydrateSession(store).copyWith(
        riderIds: updatedTrip.riderIds,
        tripStatus: updatedTrip.status,
        rideStatus: RideStatus.completed,
        safeArrivalPin: updatedTrip.safeArrivalPin ?? '',
        panicTriggered: updatedTrip.panicTriggered,
        endedAt: resolvedAt,
      ),
      RideSessionEvent(
        type: RideSessionEventType.safeArrivalConfirmed,
        occurredAt: resolvedAt,
        summary: 'Safe-arrival PIN verified successfully.',
      ),
    );

    store.write(activeTripProvider, updatedTrip);
    if (ride != null) {
      store.write(
        currentRideRequestProvider,
        ride.copyWith(
          status: RideStatus.completed,
          safeArrivalPin: expectedPin,
        ),
      );
    }
    store.write(activeRideSessionProvider, session);
    store.write(panicModeProvider, false);
    archiveActiveSession(store, occurredAt: resolvedAt);
    return true;
  }

  static void syncRemoteRideStatus(RideSessionStore store, RideStatus status) {
    switch (status) {
      case RideStatus.active:
        markTripInProgress(
          store,
          summary: 'Trip started from synchronized host updates.',
        );
        break;
      case RideStatus.completed:
        markTripArrived(
          store,
          summary: 'Destination reached from synchronized host updates.',
        );
        break;
      default:
        break;
    }
  }

  static void archiveActiveSession(
    RideSessionStore store, {
    DateTime? occurredAt,
  }) {
    final trip = store.read(activeTripProvider);
    if (trip == null) return;

    final history = store.read(rideHistoryProvider);
    if (!history.any((item) => item.id == trip.id)) {
      final archivedTrip = trip.copyWith(
        status: TripStatus.completed,
        endTime: trip.endTime ?? DateTime.now(),
      );
      store.write(rideHistoryProvider, [archivedTrip, ...history]);
    }

    final existing = _hydrateSession(store);
    final archivedAt = occurredAt ?? trip.endTime ?? DateTime.now();
    final archivedSession = existing.isArchived
        ? existing
        : _appendEvent(
            existing.copyWith(
              riderIds: trip.riderIds,
              tripStatus: trip.status,
              rideStatus: _rideStatusForTripStatus(trip.status),
              safeArrivalPin: trip.safeArrivalPin ?? existing.safeArrivalPin,
              panicTriggered: trip.panicTriggered,
              endedAt: trip.endTime ?? archivedAt,
              isArchived: true,
              archivedAt: archivedAt,
            ),
            RideSessionEvent(
              type: RideSessionEventType.sessionArchived,
              occurredAt: archivedAt,
              summary: 'Trip archived to ride history.',
            ),
          );

    final sessionHistory = store.read(rideSessionHistoryProvider);
    final alreadyArchived = sessionHistory.any(
      (session) => session.tripId == archivedSession.tripId,
    );

    store.write(activeRideSessionProvider, archivedSession);
    if (!alreadyArchived) {
      store.write(rideSessionHistoryProvider, [
        archivedSession,
        ...sessionHistory,
      ]);
    }
  }

  static void closeActiveSession(
    RideSessionStore store, {
    bool clearRideContext = false,
  }) {
    store.write(activeRideSessionProvider, null);
    store.write(activeTripProvider, null);
    store.write(panicModeProvider, false);
    store.write(routeDeviationProvider, null);
    store.write(deviationAlertDismissedProvider, false);

    if (clearRideContext) {
      store.write(currentRideRequestProvider, null);
    }
  }

  static void resetSessionState(
    RideSessionStore store, {
    bool clearRideHistory = false,
  }) {
    closeActiveSession(store, clearRideContext: true);
    store.write(rideSessionHistoryProvider, []);

    if (clearRideHistory) {
      store.write(rideHistoryProvider, []);
    }
  }

  static RideSession? _transition(
    RideSessionStore store, {
    required TripStatus nextTripStatus,
    required RideStatus nextRideStatus,
    required RideSessionEventType eventType,
    required String summary,
    DateTime? occurredAt,
    bool setTripEndTime = false,
  }) {
    final trip = store.read(activeTripProvider);
    if (trip == null) return null;

    final ride = store.read(currentRideRequestProvider);
    final session = _hydrateSession(store);

    final sameTripStatus = trip.status == nextTripStatus;
    final sameRideStatus = ride == null || ride.status == nextRideStatus;
    if (sameTripStatus && sameRideStatus) {
      return session;
    }

    final resolvedAt = occurredAt ?? DateTime.now();
    final updatedTrip = trip.copyWith(
      status: nextTripStatus,
      endTime: setTripEndTime ? (trip.endTime ?? resolvedAt) : trip.endTime,
    );
    final updatedRide = ride?.copyWith(
      status: nextRideStatus,
      readyToProceed: true,
      safeArrivalPin: ride.safeArrivalPin.isNotEmpty
          ? ride.safeArrivalPin
          : (trip.safeArrivalPin ?? session.safeArrivalPin),
    );
    final updatedSession = _appendEvent(
      session.copyWith(
        riderIds: updatedTrip.riderIds,
        tripStatus: updatedTrip.status,
        rideStatus: updatedRide?.status ?? nextRideStatus,
        safeArrivalPin: updatedTrip.safeArrivalPin ?? session.safeArrivalPin,
        panicTriggered: updatedTrip.panicTriggered,
        endedAt: setTripEndTime
            ? (updatedTrip.endTime ?? resolvedAt)
            : session.endedAt,
      ),
      RideSessionEvent(
        type: eventType,
        occurredAt: resolvedAt,
        summary: summary,
      ),
    );

    store.write(activeTripProvider, updatedTrip);
    store.write(activeRideSessionProvider, updatedSession);
    if (updatedRide != null) {
      store.write(currentRideRequestProvider, updatedRide);
    }
    return updatedSession;
  }

  static void _setActiveState(
    RideSessionStore store, {
    required RideRequest ride,
    required Trip trip,
    required RideSession session,
    required bool resetPanic,
  }) {
    store.write(currentRideRequestProvider, ride);
    store.write(activeTripProvider, trip);
    store.write(activeRideSessionProvider, session);
    store.write(routeDeviationProvider, null);
    store.write(deviationAlertDismissedProvider, false);
    if (resetPanic) {
      store.write(panicModeProvider, false);
    }
  }

  static RideSession _hydrateSession(RideSessionStore store) {
    final activeSession = store.read(activeRideSessionProvider);
    if (activeSession != null) return activeSession;

    final trip = store.read(activeTripProvider);
    final ride = store.read(currentRideRequestProvider);
    final now = DateTime.now();
    final hydratedSession = RideSession(
      rideId: ride?.id ?? _rideIdFromTrip(trip) ?? '',
      tripId: trip?.id ?? '',
      riderIds: trip?.riderIds ?? const [],
      rideStatus: ride?.status ?? _rideStatusForTripStatus(trip?.status),
      tripStatus: trip?.status ?? TripStatus.waitingForPickup,
      safeArrivalPin: trip?.safeArrivalPin ?? ride?.safeArrivalPin ?? '',
      panicTriggered: trip?.panicTriggered ?? false,
      startedAt: trip?.startTime ?? ride?.createdAt ?? now,
      endedAt: trip?.endTime,
      events: [
        RideSessionEvent(
          type: RideSessionEventType.sessionStarted,
          occurredAt: trip?.startTime ?? ride?.createdAt ?? now,
          summary: 'Session recovered from active trip state.',
        ),
      ],
    );
    store.write(activeRideSessionProvider, hydratedSession);
    return hydratedSession;
  }

  static RideSession _appendEvent(RideSession session, RideSessionEvent event) {
    final previous = session.events.isEmpty ? null : session.events.last;
    if (previous != null &&
        previous.type == event.type &&
        previous.summary == event.summary) {
      return session;
    }
    return session.copyWith(events: [...session.events, event]);
  }

  static RideStatus _rideStatusForTripStatus(TripStatus? status) {
    return switch (status) {
      TripStatus.inProgress => RideStatus.active,
      TripStatus.arrivedDestination ||
      TripStatus.completed => RideStatus.completed,
      TripStatus.emergency => RideStatus.active,
      _ => RideStatus.matched,
    };
  }

  static String? _rideIdFromTrip(Trip? trip) {
    if (trip == null) return null;
    final matchId = trip.matchId;
    if (!matchId.contains('_')) return null;
    return matchId.split('_').skip(1).join('_');
  }
}
