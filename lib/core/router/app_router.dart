// -- Shared Cab System --
// Navigation: GoRouter Setup

import 'package:go_router/go_router.dart';
import 'package:shared_cab/features/auth/login_screen.dart';
import 'package:shared_cab/features/auth/otp_screen.dart';
import 'package:shared_cab/features/home/home_screen.dart';
import 'package:shared_cab/features/ride/create_ride_screen.dart';
import 'package:shared_cab/features/matching/match_list_screen.dart';
import 'package:shared_cab/features/trip/trip_status_screen.dart';
import 'package:shared_cab/features/trip/live_tracking_screen.dart';
import 'package:shared_cab/features/trip/trip_complete_screen.dart';
import 'package:shared_cab/features/safety/panic_screen.dart';
import 'package:shared_cab/features/safety/safe_arrival_screen.dart';
import 'package:shared_cab/features/safety/emergency_contacts_screen.dart';
import 'package:shared_cab/features/profile/profile_screen.dart';
import 'package:shared_cab/features/rating/rating_screen.dart';
import 'package:shared_cab/features/shell/app_shell.dart';
import 'package:shared_cab/features/ride/recurring_rides_screen.dart';
import 'package:shared_cab/features/ride/create_recurring_ride_screen.dart';
import 'package:shared_cab/features/ride/ride_history_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Feature screens
      GoRoute(
        path: '/create-ride',
        name: 'createRide',
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: '/matches/:rideId',
        name: 'matches',
        builder: (context, state) =>
            MatchListScreen(rideId: state.pathParameters['rideId']!),
      ),
      GoRoute(
        path: '/trip/:tripId',
        name: 'tripStatus',
        builder: (context, state) =>
            TripStatusScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip-complete/:tripId',
        name: 'tripComplete',
        builder: (context, state) =>
            TripCompleteScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/panic',
        name: 'panic',
        builder: (context, state) => const PanicScreen(),
      ),
      GoRoute(
        path: '/safe-arrival/:tripId',
        name: 'safeArrival',
        builder: (context, state) =>
            SafeArrivalScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/emergency-contacts',
        name: 'emergencyContacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/rating/:tripId',
        name: 'rating',
        builder: (context, state) =>
            RatingScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/recurring-rides',
        name: 'recurringRides',
        builder: (context, state) => const RecurringRidesScreen(),
      ),
      GoRoute(
        path: '/create-recurring-ride',
        name: 'createRecurringRide',
        builder: (context, state) => const CreateRecurringRideScreen(),
      ),
      GoRoute(
        path: '/ride-history',
        name: 'rideHistory',
        builder: (context, state) => const RideHistoryScreen(),
      ),
      GoRoute(
        path: '/live-tracking/:tripId',
        name: 'liveTracking',
        builder: (context, state) =>
            LiveTrackingScreen(tripId: state.pathParameters['tripId']!),
      ),
    ],
  );
}
