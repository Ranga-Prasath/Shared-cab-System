import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/features/safety/safe_arrival_screen.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

Future<ProviderContainer> _pumpSafeArrivalApp(
  WidgetTester tester, {
  required Trip trip,
}) async {
  final container = ProviderContainer(
    overrides: [activeTripProvider.overrideWith((ref) => trip)],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/safe-arrival/${trip.id}',
    routes: [
      GoRoute(
        path: '/safe-arrival/:tripId',
        builder: (context, state) => SafeArrivalScreen(
          tripId: state.pathParameters['tripId']!,
        ),
      ),
      GoRoute(
        path: '/trip-complete/:tripId',
        name: 'tripComplete',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Trip Complete Route'))),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('SafeArrivalScreen', () {
    testWidgets('verifies the active trip pin and completes the trip', (
      tester,
    ) async {
      final container = await _pumpSafeArrivalApp(
        tester,
        trip: Trip(
          id: 'trip-1',
          matchId: 'shared_ride-1',
          riderIds: const ['host-1', 'rider-2'],
          startTime: DateTime.fromMillisecondsSinceEpoch(1000),
          safeArrivalPin: '1357',
          isNightTrip: true,
        ),
      );

      await tester.enterText(find.byType(TextField), '1357');
      await tester.tap(find.text('Verify PIN'));
      await tester.pump();

      final updatedTrip = container.read(activeTripProvider);
      expect(updatedTrip?.isPinConfirmed, isTrue);
      expect(updatedTrip?.status, TripStatus.completed);
      expect(
        find.text('Safe arrival was recorded for this trip.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Trip Complete Route'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('rejects the wrong pin and keeps the trip incomplete', (
      tester,
    ) async {
      final container = await _pumpSafeArrivalApp(
        tester,
        trip: Trip(
          id: 'trip-2',
          matchId: 'shared_ride-2',
          riderIds: const ['host-1', 'rider-2'],
          startTime: DateTime.fromMillisecondsSinceEpoch(1000),
          safeArrivalPin: '2468',
          isNightTrip: true,
        ),
      );

      await tester.enterText(find.byType(TextField), '1111');
      await tester.tap(find.text('Verify PIN'));
      await tester.pump();

      final updatedTrip = container.read(activeTripProvider);
      expect(updatedTrip?.isPinConfirmed, isFalse);
      expect(updatedTrip?.status, TripStatus.waitingForPickup);
      expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
