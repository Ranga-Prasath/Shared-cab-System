// -- Shared Cab System --
// Providers: All Riverpod providers

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:shared_cab/models/recurring_ride_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/route_deviation_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/models/user_model.dart';

final authStatusListenable = ValueNotifier<bool>(false);

// Auth State
final isLoggedInProvider = StateProvider<bool>((ref) => false);
final currentUserProvider = StateProvider<User?>((ref) => null);

final effectiveCurrentUserProvider = Provider<User>((ref) {
  return ref.watch(currentUserProvider) ?? MockData.demoUser;
});

// Night Mode
final currentTimeProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

final isNightModeProvider = Provider<bool>((ref) {
  final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
  return isNightDateTime(now);
});

final nightModeOverrideProvider = StateProvider<bool?>((ref) => null);

final effectiveNightModeProvider = Provider<bool>((ref) {
  final override = ref.watch(nightModeOverrideProvider);
  if (override != null) return override;
  return ref.watch(isNightModeProvider);
});

// Ride
final currentRideRequestProvider = StateProvider<RideRequest?>((ref) => null);

// Trip
final activeTripProvider = StateProvider<Trip?>((ref) => null);
final rideHistoryProvider = StateProvider<List<Trip>>((ref) => []);

void archiveTripToHistory(Ref ref, Trip trip) {
  final history = ref.read(rideHistoryProvider);
  if (history.any((item) => item.id == trip.id)) return;

  final archivedTrip = trip.copyWith(
    status: TripStatus.completed,
    endTime: trip.endTime ?? DateTime.now(),
  );

  ref.read(rideHistoryProvider.notifier).state = [archivedTrip, ...history];
}

// Safety
final sameGenderOnlyProvider = StateProvider<bool>((ref) => true);
final panicModeProvider = StateProvider<bool>((ref) => false);

// Route Deviation
final routeDeviationProvider = StateProvider<RouteDeviation?>((ref) => null);
final deviationAlertDismissedProvider = StateProvider<bool>((ref) => false);

// Recurring Rides
final recurringRidesProvider = StateProvider<List<RecurringRide>>((ref) => []);

Trip? findTripById(Ref ref, String tripId) {
  final active = ref.read(activeTripProvider);
  if (active != null && active.id == tripId) return active;

  final history = ref.read(rideHistoryProvider);
  for (final trip in history) {
    if (trip.id == tripId) return trip;
  }
  return null;
}

void setLoggedIn(Ref ref, User user) {
  ref.read(isLoggedInProvider.notifier).state = true;
  ref.read(currentUserProvider.notifier).state = user;
  authStatusListenable.value = true;
}

void resetAllState(Ref ref) {
  ref.read(isLoggedInProvider.notifier).state = false;
  ref.read(currentUserProvider.notifier).state = null;
  ref.read(nightModeOverrideProvider.notifier).state = null;
  ref.read(currentRideRequestProvider.notifier).state = null;
  ref.read(activeTripProvider.notifier).state = null;
  ref.read(rideHistoryProvider.notifier).state = [];
  ref.read(sameGenderOnlyProvider.notifier).state = true;
  ref.read(panicModeProvider.notifier).state = false;
  ref.read(routeDeviationProvider.notifier).state = null;
  ref.read(deviationAlertDismissedProvider.notifier).state = false;
  ref.read(recurringRidesProvider.notifier).state = [];
  authStatusListenable.value = false;
}
