// -- Shared Cab System --
// Core model: Match Result

import 'package:flutter/foundation.dart';

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

  MatchResult copyWith({
    String? id,
    String? rideRequestId,
    List<MatchedRider>? riders,
    double? routeOverlapPercent,
    double? estimatedFarePerPerson,
    double? totalFare,
    double? savingsPercent,
    DateTime? matchedAt,
  }) {
    return MatchResult(
      id: id ?? this.id,
      rideRequestId: rideRequestId ?? this.rideRequestId,
      riders: riders ?? this.riders,
      routeOverlapPercent: routeOverlapPercent ?? this.routeOverlapPercent,
      estimatedFarePerPerson:
          estimatedFarePerPerson ?? this.estimatedFarePerPerson,
      totalFare: totalFare ?? this.totalFare,
      savingsPercent: savingsPercent ?? this.savingsPercent,
      matchedAt: matchedAt ?? this.matchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rideRequestId': rideRequestId,
    'riders': riders.map((r) => r.toJson()).toList(),
    'routeOverlapPercent': routeOverlapPercent,
    'estimatedFarePerPerson': estimatedFarePerPerson,
    'totalFare': totalFare,
    'savingsPercent': savingsPercent,
    'matchedAt': matchedAt.toIso8601String(),
  };

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final ridersJson = json['riders'] as List<dynamic>? ?? const [];
    return MatchResult(
      id: json['id'] as String,
      rideRequestId: json['rideRequestId'] as String,
      riders: ridersJson
          .map((item) => MatchedRider.fromJson(item as Map<String, dynamic>))
          .toList(),
      routeOverlapPercent: (json['routeOverlapPercent'] as num).toDouble(),
      estimatedFarePerPerson: (json['estimatedFarePerPerson'] as num)
          .toDouble(),
      totalFare: (json['totalFare'] as num).toDouble(),
      savingsPercent: (json['savingsPercent'] as num).toDouble(),
      matchedAt: DateTime.parse(json['matchedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'MatchResult(id: $id, rideRequestId: $rideRequestId, riderCount: ${riders.length}, overlap: $routeOverlapPercent, farePerPerson: $estimatedFarePerPerson)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchResult &&
        other.id == id &&
        other.rideRequestId == rideRequestId &&
        listEquals(other.riders, riders) &&
        other.routeOverlapPercent == routeOverlapPercent &&
        other.estimatedFarePerPerson == estimatedFarePerPerson &&
        other.totalFare == totalFare &&
        other.savingsPercent == savingsPercent &&
        other.matchedAt == matchedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    rideRequestId,
    Object.hashAll(riders),
    routeOverlapPercent,
    estimatedFarePerPerson,
    totalFare,
    savingsPercent,
    matchedAt,
  );
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

  MatchedRider copyWith({
    String? userId,
    String? name,
    String? gender,
    double? rating,
    String? pickupAddress,
    String? dropoffAddress,
    int? timeDifferenceMinutes,
  }) {
    return MatchedRider(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      timeDifferenceMinutes:
          timeDifferenceMinutes ?? this.timeDifferenceMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'gender': gender,
    'rating': rating,
    'pickupAddress': pickupAddress,
    'dropoffAddress': dropoffAddress,
    'timeDifferenceMinutes': timeDifferenceMinutes,
  };

  factory MatchedRider.fromJson(Map<String, dynamic> json) {
    return MatchedRider(
      userId: json['userId'] as String,
      name: json['name'] as String,
      gender: json['gender'] as String,
      rating: (json['rating'] as num).toDouble(),
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String,
      timeDifferenceMinutes:
          (json['timeDifferenceMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() {
    return 'MatchedRider(userId: $userId, name: $name, gender: $gender, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchedRider &&
        other.userId == userId &&
        other.name == name &&
        other.gender == gender &&
        other.rating == rating &&
        other.pickupAddress == pickupAddress &&
        other.dropoffAddress == dropoffAddress &&
        other.timeDifferenceMinutes == timeDifferenceMinutes;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    name,
    gender,
    rating,
    pickupAddress,
    dropoffAddress,
    timeDifferenceMinutes,
  );
}
