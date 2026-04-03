// SPEC: Constraint-Based Matching Pipeline
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WHAT IT DOES:
//   Evaluates candidate rides through one ordered matching pipeline so screens
//   receive ranked, explainable matches from a single source of truth.
//
// DATA OBJECTS:
//   MatchContext - current rider state, safety flags, preferences, and route
//   ScoredMatch - surviving ride candidate with score and human-readable reasons
//
// OPERATIONS:
//   evaluate: candidate rides + context -> sorted scored matches
//   routePointsForRide: RideRequest -> route points used by geometry checks
//   preferenceCompatibilityScore: rider prefs + candidate prefs -> 0..1 signal
//
// EDGE CASES HANDLED:
//   • route-based matching falls back to pickup/dropoff when stored route paths
//     are missing
//   • discovery mode can score rides from current GPS even without a draft ride
//   • preference matching is soft-scored, not hard-filtered, because the current
//     booleans describe comfort signals rather than strict incompatibility rules
//
// ASSUMPTIONS MADE:
//   • freshness remains a 30-minute window to match current Firestore behavior
//   • spatial threshold stays configurable so screens can preserve current
//     behavior while routing all decisions through one pipeline
//
// DONE WHEN:
//   match screens call only this pipeline for filtering and ranking, night-mode
//   safety is enforced centrally, and tests verify the core constraints.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/constants/app_constants.dart';
import 'package:shared_cab/features/trip/utils/trip_route_builder.dart';
import 'package:shared_cab/models/ride_preferences_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/scored_match_model.dart';

class MatchContext {
  const MatchContext({
    required this.currentUserId,
    required this.currentUserGender,
    required this.riderPreferences,
    required this.isNightMode,
    required this.sameGenderOnly,
    required this.now,
    this.referenceRide,
    this.currentLocation,
    this.desiredDepartureTime,
    this.maxFreshnessMinutes = 30,
    this.minRouteOverlapPercent = AppConstants.routeOverlapThresholdPercent,
    this.maxDepartureDifferenceMinutes = 0,
    this.maxDistanceToRouteKm = 5,
  });

  final String currentUserId;
  final String currentUserGender;
  final RidePreferences riderPreferences;
  final bool isNightMode;
  final bool sameGenderOnly;
  final DateTime now;
  final RideRequest? referenceRide;
  final LatLng? currentLocation;
  final DateTime? desiredDepartureTime;
  final int maxFreshnessMinutes;
  final double minRouteOverlapPercent;
  final int maxDepartureDifferenceMinutes;
  final double maxDistanceToRouteKm;
}

class MatchingPipeline {
  MatchingPipeline._();

  // Service discovery stops at backend lifecycle availability.
  // Everything user-specific after that, including freshness and identity, is
  // decided here so both matching screens use one eligibility contract.
  static const List<_MatchConstraint> _constraints = [
    _IdentityConstraint(),
    _FreshnessConstraint(),
    _CapacityConstraint(),
    _SpatialConstraint(),
    _TemporalConstraint(),
    _SafetyConstraint(),
    _PreferenceConstraint(),
  ];

  static List<ScoredMatch> evaluate({
    required List<RideRequest> candidates,
    required MatchContext context,
  }) {
    final results = <ScoredMatch>[];

    for (final candidate in candidates) {
      final accumulator = _MatchAccumulator();
      var passed = true;

      for (final constraint in _constraints) {
        if (!constraint.evaluate(candidate, context, accumulator)) {
          passed = false;
          break;
        }
      }

      if (!passed) continue;

      final score = _MatchScorer.score(
        candidate: candidate,
        context: context,
        accumulator: accumulator,
      );

      results.add(
        ScoredMatch(
          ride: candidate,
          score: score,
          routeOverlapPercent: accumulator.routeOverlapPercent,
          departureDifferenceMinutes: accumulator.departureDifferenceMinutes,
          distanceToRouteKm: accumulator.distanceToRouteKm,
          preferenceCompatibilityScore:
              accumulator.preferenceCompatibilityScore,
          reasons: List.unmodifiable(accumulator.reasons),
        ),
      );
    }

    results.sort((left, right) {
      final scoreOrder = right.score.compareTo(left.score);
      if (scoreOrder != 0) return scoreOrder;

      final overlapOrder = right.routeOverlapPercent.compareTo(
        left.routeOverlapPercent,
      );
      if (overlapOrder != 0) return overlapOrder;

      final createdAtOrder = right.ride.createdAt.compareTo(
        left.ride.createdAt,
      );
      if (createdAtOrder != 0) return createdAtOrder;

      return left.ride.id.compareTo(right.ride.id);
    });

    return results;
  }

  static List<LatLng> routePointsForRide(RideRequest ride) {
    if (ride.routePath.length >= 2) {
      return ride.routePath
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }

    return [
      LatLng(ride.pickup.latitude, ride.pickup.longitude),
      LatLng(ride.dropoff.latitude, ride.dropoff.longitude),
    ];
  }

  static double preferenceCompatibilityScore(
    RidePreferences riderPreferences,
    RidePreferences candidatePreferences,
  ) {
    const weightedSignals = <double>[
      1.0, // AC preference
      1.5, // music
      2.0, // pet
      1.5, // luggage
      3.0, // silent ride
      0.5, // window
    ];

    final riderSignals = [
      riderPreferences.acPreferred,
      riderPreferences.musicAllowed,
      riderPreferences.petFriendly,
      riderPreferences.extraLuggage,
      riderPreferences.silentRide,
      riderPreferences.windowSeat,
    ];
    final candidateSignals = [
      candidatePreferences.acPreferred,
      candidatePreferences.musicAllowed,
      candidatePreferences.petFriendly,
      candidatePreferences.extraLuggage,
      candidatePreferences.silentRide,
      candidatePreferences.windowSeat,
    ];

    var matchedWeight = 0.0;
    var totalWeight = 0.0;
    for (var index = 0; index < weightedSignals.length; index++) {
      final weight = weightedSignals[index];
      totalWeight += weight;
      if (riderSignals[index] == candidateSignals[index]) {
        matchedWeight += weight;
      }
    }

    if (totalWeight == 0) return 1;
    return matchedWeight / totalWeight;
  }
}

abstract class _MatchConstraint {
  const _MatchConstraint();

  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  );
}

class _IdentityConstraint extends _MatchConstraint {
  const _IdentityConstraint();

  @override
  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  ) {
    if (candidate.userId == context.currentUserId) return false;
    if (candidate.coRiderIds.contains(context.currentUserId)) return false;
    return true;
  }
}

class _FreshnessConstraint extends _MatchConstraint {
  const _FreshnessConstraint();

  @override
  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  ) {
    final ageMinutes = context.now.difference(candidate.createdAt).inMinutes;
    if (ageMinutes > context.maxFreshnessMinutes) return false;

    accumulator.freshnessRatio =
        1 -
        (ageMinutes.clamp(0, context.maxFreshnessMinutes) /
            context.maxFreshnessMinutes);
    return true;
  }
}

class _CapacityConstraint extends _MatchConstraint {
  const _CapacityConstraint();

  @override
  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  ) {
    final occupiedSeats = candidate.coRiderIds.toSet().length;
    if (occupiedSeats >= candidate.maxCoRiders) return false;

    final remainingSeats = candidate.maxCoRiders - occupiedSeats;
    accumulator.remainingSeatRatio = candidate.maxCoRiders <= 0
        ? 0
        : remainingSeats / candidate.maxCoRiders;
    return true;
  }
}

class _SpatialConstraint extends _MatchConstraint {
  const _SpatialConstraint();

  @override
  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  ) {
    final candidateRoute = MatchingPipeline.routePointsForRide(candidate);

    if (context.referenceRide != null) {
      final overlap = TripRouteBuilder.routeOverlapPercent(
        MatchingPipeline.routePointsForRide(context.referenceRide!),
        candidateRoute,
      ).clamp(0, 100).toDouble();
      accumulator.routeOverlapPercent = overlap;
      if (overlap < context.minRouteOverlapPercent) return false;

      accumulator.addReason('${overlap.toStringAsFixed(0)}% route overlap');
      return true;
    }

    if (context.currentLocation != null) {
      final distanceKm = TripRouteBuilder.pointDistanceToRouteKm(
        context.currentLocation!,
        candidateRoute,
      );
      accumulator.distanceToRouteKm = distanceKm;
      if (distanceKm > context.maxDistanceToRouteKm) return false;

      accumulator.addReason(
        '${distanceKm.toStringAsFixed(1)} km from your current location',
      );
      return true;
    }

    return false;
  }
}

class _TemporalConstraint extends _MatchConstraint {
  const _TemporalConstraint();

  @override
  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  ) {
    final referenceTime =
        context.referenceRide?.departureTime ??
        context.desiredDepartureTime ??
        context.now;

    final differenceMinutes = _differenceInWholeMinutes(
      candidate.departureTime,
      referenceTime,
    );
    accumulator.departureDifferenceMinutes = differenceMinutes;
    if (context.maxDepartureDifferenceMinutes <= 0) {
      if (!_isSameMinute(candidate.departureTime, referenceTime)) {
        return false;
      }
    } else if (differenceMinutes > context.maxDepartureDifferenceMinutes) {
      return false;
    }

    accumulator.addReason('$differenceMinutes min departure gap');
    return true;
  }
}

class _SafetyConstraint extends _MatchConstraint {
  const _SafetyConstraint();

  @override
  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  ) {
    if (!context.isNightMode || !context.sameGenderOnly) return true;

    final riderGender = context.currentUserGender.trim().toLowerCase();
    final candidateGender = candidate.userGender.trim().toLowerCase();
    if (riderGender.isEmpty || candidateGender.isEmpty) return false;
    if (riderGender != candidateGender) return false;

    accumulator.sameGenderNightMatch = true;
    accumulator.addReason('Same-gender night match');
    return true;
  }
}

class _PreferenceConstraint extends _MatchConstraint {
  const _PreferenceConstraint();

  @override
  bool evaluate(
    RideRequest candidate,
    MatchContext context,
    _MatchAccumulator accumulator,
  ) {
    final compatibility = MatchingPipeline.preferenceCompatibilityScore(
      context.riderPreferences,
      candidate.preferenceSnapshot,
    );
    accumulator.preferenceCompatibilityScore = compatibility;

    if (compatibility >= 0.8) {
      accumulator.addReason('Comfort preferences align strongly');
    } else if (compatibility >= 0.6) {
      accumulator.addReason('Comfort preferences mostly align');
    }

    return true;
  }
}

class _MatchScorer {
  const _MatchScorer._();

  static double score({
    required RideRequest candidate,
    required MatchContext context,
    required _MatchAccumulator accumulator,
  }) {
    var score = 0.0;

    if (accumulator.routeOverlapPercent > 0) {
      score += accumulator.routeOverlapPercent * 0.6;
    } else if (accumulator.distanceToRouteKm != null) {
      final normalizedDistance =
          1 -
          ((accumulator.distanceToRouteKm!.clamp(
                0,
                context.maxDistanceToRouteKm,
              )) /
              context.maxDistanceToRouteKm);
      score += normalizedDistance * 35;
    }

    if (accumulator.departureDifferenceMinutes != null) {
      if (context.maxDepartureDifferenceMinutes <= 0) {
        if (accumulator.departureDifferenceMinutes == 0) {
          score += 20;
        }
      } else {
        final normalizedDeparture =
            1 -
            (accumulator.departureDifferenceMinutes!.clamp(
                  0,
                  context.maxDepartureDifferenceMinutes,
                ) /
                context.maxDepartureDifferenceMinutes);
        score += normalizedDeparture * 20;
      }
    }

    score += accumulator.preferenceCompatibilityScore * 15;
    score += accumulator.remainingSeatRatio * 5;
    score += accumulator.freshnessRatio * 5;
    if (accumulator.sameGenderNightMatch) {
      score += 5;
    }

    return score;
  }
}

bool _isSameMinute(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day &&
      left.hour == right.hour &&
      left.minute == right.minute;
}

int _differenceInWholeMinutes(DateTime left, DateTime right) {
  return left.difference(right).inMinutes.abs();
}

class _MatchAccumulator {
  double routeOverlapPercent = 0;
  int? departureDifferenceMinutes;
  double? distanceToRouteKm;
  double preferenceCompatibilityScore = 0;
  double freshnessRatio = 0;
  double remainingSeatRatio = 0;
  bool sameGenderNightMatch = false;
  final List<String> reasons = <String>[];

  void addReason(String value) {
    if (value.isEmpty || reasons.contains(value)) return;
    reasons.add(value);
  }
}
