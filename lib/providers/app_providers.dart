// -- Shared Cab System --
// Providers: All Riverpod providers

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_cab/core/services/auth_service.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:shared_cab/models/recurring_ride_model.dart';
import 'package:shared_cab/models/ride_preferences_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/route_deviation_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/models/user_model.dart';
import 'package:shared_cab/models/location_model.dart';

// Auth State
final currentUserOverrideProvider = StateProvider<User?>((ref) => null);

final authStateProvider = StreamProvider<fb.User?>((ref) {
  return AuthService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final overrideUser = ref.watch(currentUserOverrideProvider);
  if (overrideUser != null) return overrideUser;

  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  final fallbackUser = AuthService.currentUserProfile;
  if (firebaseUser == null) return fallbackUser;

  if (fallbackUser != null && fallbackUser.id == firebaseUser.uid) {
    return fallbackUser;
  }

  final displayName =
      firebaseUser.displayName ??
      firebaseUser.email?.split('@').first ??
      'User';

  return User(
    id: firebaseUser.uid,
    name: displayName,
    phone: '',
    email: firebaseUser.email ?? '',
    gender: fallbackUser?.gender ?? 'other',
    rating: fallbackUser?.rating ?? 5.0,
    totalTrips: fallbackUser?.totalTrips ?? 0,
    profileImageUrl: fallbackUser?.profileImageUrl,
    emergencyContacts: fallbackUser?.emergencyContacts ?? const [],
    isVerified: true,
  );
});

final isLoggedInProvider = Provider<bool>((ref) {
  final overrideUser = ref.watch(currentUserOverrideProvider);
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  return overrideUser != null ||
      firebaseUser != null ||
      AuthService.currentUserProfile != null;
});

final effectiveCurrentUserProvider = Provider<User>((ref) {
  return ref.watch(currentUserProvider) ?? MockData.demoUser;
});

// Night Mode
final currentTimeProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  while (true) {
    await Future<void>.delayed(const Duration(minutes: 1));
    yield DateTime.now();
  }
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

// Ride Preferences
final ridePreferencesProvider = StateProvider<RidePreferences>(
  (ref) => const RidePreferences(),
);

/// Stores pickup locations for each rider in a shared trip, keyed by rider name.
/// Each entry: { 'name': String, 'pickup': LocationPoint }
final coRiderPickupLocationsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);
