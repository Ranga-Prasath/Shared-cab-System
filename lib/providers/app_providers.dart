// -- Shared Cab System --
// Providers: All Riverpod providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:shared_cab/models/recurring_ride_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/route_deviation_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/models/user_model.dart';

// Auth State
final isLoggedInProvider = StateProvider<bool>((ref) => false);
final currentUserProvider = StateProvider<User?>((ref) => null);

final effectiveCurrentUserProvider = Provider<User>((ref) {
  return ref.watch(currentUserProvider) ?? MockData.demoUser;
});

// Night Mode
final isNightModeProvider = Provider<bool>((ref) {
  return isNightDateTime(DateTime.now());
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

void archiveTripToHistory(WidgetRef ref, Trip trip) {
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

// Navigation
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Route Deviation
final routeDeviationProvider = StateProvider<RouteDeviation?>((ref) => null);
final deviationAlertDismissedProvider = StateProvider<bool>((ref) => false);

// Recurring Rides
final recurringRidesProvider = StateProvider<List<RecurringRide>>((ref) => []);
