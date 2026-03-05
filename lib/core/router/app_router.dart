// -- Shared Cab System --
// Navigation: GoRouter Setup

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/router/app_routes.dart';
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
import 'package:shared_cab/providers/app_providers.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: AppRoutes.loginPath,
    refreshListenable: authStatusListenable,
    redirect: (context, state) {
      final isLoggedIn = authStatusListenable.value;
      final path = state.uri.path;
      final isAuthPath =
          path == AppRoutes.loginPath || path == AppRoutes.otpPath;

      if (!isLoggedIn && !isAuthPath) return AppRoutes.loginPath;
      if (isLoggedIn && isAuthPath) return AppRoutes.homePath;
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpPath,
        name: AppRoutes.otpName,
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
            path: AppRoutes.homePath,
            name: AppRoutes.homeName,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.profilePath,
            name: AppRoutes.profileName,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Feature screens
      GoRoute(
        path: AppRoutes.createRidePath,
        name: AppRoutes.createRideName,
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchesPath,
        name: AppRoutes.matchesName,
        builder: (context, state) {
          final rideId = _requiredParam(state, AppRoutes.rideIdParam);
          if (rideId == null) {
            return const _InvalidRouteScreen(message: 'Missing ride ID');
          }
          return MatchListScreen(rideId: rideId);
        },
      ),
      GoRoute(
        path: AppRoutes.tripStatusPath,
        name: AppRoutes.tripStatusName,
        builder: (context, state) {
          final tripId = _requiredParam(state, AppRoutes.tripIdParam);
          if (tripId == null) {
            return const _InvalidRouteScreen(message: 'Missing trip ID');
          }
          return TripStatusScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.tripCompletePath,
        name: AppRoutes.tripCompleteName,
        builder: (context, state) {
          final tripId = _requiredParam(state, AppRoutes.tripIdParam);
          if (tripId == null) {
            return const _InvalidRouteScreen(message: 'Missing trip ID');
          }
          return TripCompleteScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.panicPath,
        name: AppRoutes.panicName,
        builder: (context, state) => const PanicScreen(),
      ),
      GoRoute(
        path: AppRoutes.safeArrivalPath,
        name: AppRoutes.safeArrivalName,
        builder: (context, state) {
          final tripId = _requiredParam(state, AppRoutes.tripIdParam);
          if (tripId == null) {
            return const _InvalidRouteScreen(message: 'Missing trip ID');
          }
          return SafeArrivalScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.emergencyContactsPath,
        name: AppRoutes.emergencyContactsName,
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: AppRoutes.ratingPath,
        name: AppRoutes.ratingName,
        builder: (context, state) {
          final tripId = _requiredParam(state, AppRoutes.tripIdParam);
          if (tripId == null) {
            return const _InvalidRouteScreen(message: 'Missing trip ID');
          }
          return RatingScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.recurringRidesPath,
        name: AppRoutes.recurringRidesName,
        builder: (context, state) => const RecurringRidesScreen(),
      ),
      GoRoute(
        path: AppRoutes.createRecurringRidePath,
        name: AppRoutes.createRecurringRideName,
        builder: (context, state) => const CreateRecurringRideScreen(),
      ),
      GoRoute(
        path: AppRoutes.rideHistoryPath,
        name: AppRoutes.rideHistoryName,
        builder: (context, state) => const RideHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.liveTrackingPath,
        name: AppRoutes.liveTrackingName,
        builder: (context, state) {
          final tripId = _requiredParam(state, AppRoutes.tripIdParam);
          if (tripId == null) {
            return const _InvalidRouteScreen(message: 'Missing trip ID');
          }
          return LiveTrackingScreen(tripId: tripId);
        },
      ),
    ],
  );

  static String? _requiredParam(GoRouterState state, String key) {
    final value = state.pathParameters[key];
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

class _InvalidRouteScreen extends StatelessWidget {
  final String message;

  const _InvalidRouteScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
