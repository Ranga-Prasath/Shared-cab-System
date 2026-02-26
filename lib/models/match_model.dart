// -- Shared Cab System --
// Core model: Match Result

class MatchResult {
  final String id;
  final String rideRequestId;
  final List<MatchedRider> riders;
  final double routeOverlapPercent;
  final double estimatedFarePerPerson;
  final double totalFare;
  final double savingsPercent;
  final DateTime matchedAt;

  const MatchResult({
    required this.id,
    required this.rideRequestId,
    required this.riders,
    required this.routeOverlapPercent,
    required this.estimatedFarePerPerson,
    required this.totalFare,
    required this.savingsPercent,
    required this.matchedAt,
  });

  int get riderCount => riders.length;
}

class MatchedRider {
  final String userId;
  final String name;
  final String gender;
  final double rating;
  final String pickupAddress;
  final String dropoffAddress;
  final int timeDifferenceMinutes;

  const MatchedRider({
    required this.userId,
    required this.name,
    required this.gender,
    required this.rating,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.timeDifferenceMinutes = 0,
  });
}
