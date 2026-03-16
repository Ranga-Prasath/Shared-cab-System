import 'package:shared_cab/models/ride_request_model.dart';

class ScoredMatch {
  const ScoredMatch({
    required this.ride,
    required this.score,
    required this.routeOverlapPercent,
    required this.preferenceCompatibilityScore,
    required this.reasons,
    this.departureDifferenceMinutes,
    this.distanceToRouteKm,
  });

  final RideRequest ride;
  final double score;
  final double routeOverlapPercent;
  final int? departureDifferenceMinutes;
  final double? distanceToRouteKm;
  final double preferenceCompatibilityScore;
  final List<String> reasons;
}
