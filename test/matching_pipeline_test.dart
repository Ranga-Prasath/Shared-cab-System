import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/matching/matching_pipeline.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_preferences_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';

RideRequest _buildRide({
  required String id,
  required String userId,
  required String userGender,
  required DateTime departureTime,
  required DateTime createdAt,
  required List<RideRoutePoint> routePath,
  RidePreferences preferenceSnapshot = const RidePreferences(),
  int maxCoRiders = 3,
  List<String> coRiderIds = const [],
}) {
  return RideRequest(
    id: id,
    userId: userId,
    userName: id,
    userGender: userGender,
    pickup: LocationPoint(
      latitude: routePath.first.latitude,
      longitude: routePath.first.longitude,
      address: 'Pickup $id',
    ),
    dropoff: LocationPoint(
      latitude: routePath.last.latitude,
      longitude: routePath.last.longitude,
      address: 'Dropoff $id',
    ),
    departureTime: departureTime,
    createdAt: createdAt,
    routePath: routePath,
    preferenceSnapshot: preferenceSnapshot,
    maxCoRiders: maxCoRiders,
    coRiderIds: coRiderIds,
  );
}

List<RideRoutePoint> _route(List<(double, double)> points) {
  return points
      .map((point) => RideRoutePoint(latitude: point.$1, longitude: point.$2))
      .toList();
}

void main() {
  group('MatchingPipeline', () {
    final baseTime = DateTime(2026, 3, 15, 22, 0);
    final referenceRide = _buildRide(
      id: 'reference',
      userId: 'user-me',
      userGender: 'female',
      departureTime: baseTime,
      createdAt: baseTime.subtract(const Duration(minutes: 2)),
      routePath: _route([
        (13.0000, 80.0000),
        (13.0500, 80.0500),
        (13.1000, 80.1000),
      ]),
      preferenceSnapshot: const RidePreferences(
        silentRide: true,
        musicAllowed: false,
        extraLuggage: true,
      ),
    );

    MatchContext buildContext({
      RideRequest? referenceRide,
      LatLng? currentLocation,
      bool isNightMode = true,
      bool sameGenderOnly = true,
    }) {
      return MatchContext(
        currentUserId: 'user-me',
        currentUserGender: 'female',
        riderPreferences: const RidePreferences(
          silentRide: true,
          musicAllowed: false,
          extraLuggage: true,
        ),
        isNightMode: isNightMode,
        sameGenderOnly: sameGenderOnly,
        now: baseTime,
        referenceRide: referenceRide,
        currentLocation: currentLocation,
      );
    }

    test('enforces same-gender night matching centrally', () {
      final femaleCandidate = _buildRide(
        id: 'female',
        userId: 'user-f',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 1)),
        routePath: _route([
          (13.0000, 80.0000),
          (13.0500, 80.0500),
          (13.1000, 80.1000),
        ]),
      );
      final maleCandidate = _buildRide(
        id: 'male',
        userId: 'user-m',
        userGender: 'male',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 1)),
        routePath: _route([
          (13.0000, 80.0000),
          (13.0500, 80.0500),
          (13.1000, 80.1000),
        ]),
      );

      final results = MatchingPipeline.evaluate(
        candidates: [femaleCandidate, maleCandidate],
        context: buildContext(referenceRide: referenceRide),
      );

      expect(results.map((match) => match.ride.id), ['female']);
      expect(results.single.reasons, contains('Same-gender night match'));
    });

    test('applies temporal and capacity constraints before scoring', () {
      final validRide = _buildRide(
        id: 'valid',
        userId: 'user-valid',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 10)),
        createdAt: baseTime.subtract(const Duration(minutes: 3)),
        routePath: referenceRide.routePath,
      );
      final lateRide = _buildRide(
        id: 'late',
        userId: 'user-late',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 25)),
        createdAt: baseTime.subtract(const Duration(minutes: 3)),
        routePath: referenceRide.routePath,
      );
      final fullRide = _buildRide(
        id: 'full',
        userId: 'user-full',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 10)),
        createdAt: baseTime.subtract(const Duration(minutes: 3)),
        routePath: referenceRide.routePath,
        maxCoRiders: 1,
        coRiderIds: const ['taken-seat'],
      );

      final results = MatchingPipeline.evaluate(
        candidates: [validRide, lateRide, fullRide],
        context: buildContext(referenceRide: referenceRide),
      );

      expect(results.map((match) => match.ride.id), ['valid']);
      expect(results.single.departureDifferenceMinutes, 10);
    });

    test(
      'uses current location for discovery mode when no reference ride exists',
      () {
        final nearbyRide = _buildRide(
          id: 'nearby',
          userId: 'user-nearby',
          userGender: 'female',
          departureTime: baseTime.add(const Duration(minutes: 5)),
          createdAt: baseTime.subtract(const Duration(minutes: 4)),
          routePath: _route([(13.0000, 80.0000), (13.0100, 80.0100)]),
        );
        final farRide = _buildRide(
          id: 'far',
          userId: 'user-far',
          userGender: 'female',
          departureTime: baseTime.add(const Duration(minutes: 5)),
          createdAt: baseTime.subtract(const Duration(minutes: 4)),
          routePath: _route([(12.7000, 79.7000), (12.7100, 79.7100)]),
        );

        final results = MatchingPipeline.evaluate(
          candidates: [nearbyRide, farRide],
          context: buildContext(
            currentLocation: const LatLng(13.0050, 80.0050),
            referenceRide: null,
          ),
        );

        expect(results.map((match) => match.ride.id), ['nearby']);
        expect(results.single.distanceToRouteKm, lessThan(1.0));
      },
    );

    test('fails closed when no route or location context exists', () {
      final candidate = _buildRide(
        id: 'candidate',
        userId: 'user-candidate',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 4)),
        routePath: _route([(13.0000, 80.0000), (13.0100, 80.0100)]),
      );

      final results = MatchingPipeline.evaluate(
        candidates: [candidate],
        context: buildContext(referenceRide: null, currentLocation: null),
      );

      expect(results, isEmpty);
    });

    test('scores stronger preference alignment above weaker matches', () {
      final strongPreferenceRide = _buildRide(
        id: 'strong',
        userId: 'user-strong',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 1)),
        routePath: referenceRide.routePath,
        preferenceSnapshot: const RidePreferences(
          silentRide: true,
          musicAllowed: false,
          extraLuggage: true,
        ),
      );
      final weakPreferenceRide = _buildRide(
        id: 'weak',
        userId: 'user-weak',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 1)),
        routePath: referenceRide.routePath,
        preferenceSnapshot: const RidePreferences(
          silentRide: false,
          musicAllowed: true,
          extraLuggage: false,
        ),
      );

      final results = MatchingPipeline.evaluate(
        candidates: [weakPreferenceRide, strongPreferenceRide],
        context: buildContext(referenceRide: referenceRide),
      );

      expect(results.map((match) => match.ride.id), ['strong', 'weak']);
      expect(
        results.first.preferenceCompatibilityScore,
        greaterThan(results.last.preferenceCompatibilityScore),
      );
      expect(results.first.reasons.join(' '), contains('Comfort preferences'));
    });

    test('keeps freshness and identity filtering inside the pipeline', () {
      final requestedCandidate = _buildRide(
        id: 'requested',
        userId: 'user-requested',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 5)),
        routePath: referenceRide.routePath,
      ).copyWith(status: RideStatus.requested);
      final staleCandidate = _buildRide(
        id: 'stale',
        userId: 'user-stale',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 45)),
        routePath: referenceRide.routePath,
      );
      final sameUserCandidate = _buildRide(
        id: 'same-user',
        userId: 'user-me',
        userGender: 'female',
        departureTime: baseTime.add(const Duration(minutes: 5)),
        createdAt: baseTime.subtract(const Duration(minutes: 5)),
        routePath: referenceRide.routePath,
      );

      final results = MatchingPipeline.evaluate(
        candidates: [requestedCandidate, staleCandidate, sameUserCandidate],
        context: buildContext(referenceRide: referenceRide),
      );

      expect(results.map((match) => match.ride.id), ['requested']);
    });
  });
}
