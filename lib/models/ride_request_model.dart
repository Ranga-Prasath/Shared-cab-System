// -- Shared Cab System --
// Core model: Ride Request

import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';

enum RideStatus { pending, matched, active, completed, cancelled }

class RideRequest {
  final String id;
  final String userId;
  final LocationPoint pickup;
  final LocationPoint dropoff;
  final DateTime departureTime;
  final RideStatus status;
  final int maxCoRiders;
  final String? matchId;
  final DateTime createdAt;

  const RideRequest({
    required this.id,
    required this.userId,
    required this.pickup,
    required this.dropoff,
    required this.departureTime,
    this.status = RideStatus.pending,
    this.maxCoRiders = 3,
    this.matchId,
    required this.createdAt,
  });

  /// Whether this ride is during night hours (9 PM - 6 AM)
  bool get isNightRide {
    return isNightDateTime(departureTime);
  }

  RideRequest copyWith({
    String? id,
    String? userId,
    LocationPoint? pickup,
    LocationPoint? dropoff,
    DateTime? departureTime,
    RideStatus? status,
    int? maxCoRiders,
    String? matchId,
    DateTime? createdAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      departureTime: departureTime ?? this.departureTime,
      status: status ?? this.status,
      maxCoRiders: maxCoRiders ?? this.maxCoRiders,
      matchId: matchId ?? this.matchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'departureTime': departureTime.toIso8601String(),
    'status': status.name,
    'maxCoRiders': maxCoRiders,
    'matchId': matchId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      pickup: LocationPoint.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: LocationPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
      departureTime: DateTime.parse(json['departureTime'] as String),
      status: RideStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => RideStatus.pending,
      ),
      maxCoRiders: (json['maxCoRiders'] as num?)?.toInt() ?? 3,
      matchId: json['matchId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'RideRequest(id: $id, userId: $userId, status: $status, maxCoRiders: $maxCoRiders, departureTime: $departureTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideRequest &&
        other.id == id &&
        other.userId == userId &&
        other.pickup == pickup &&
        other.dropoff == dropoff &&
        other.departureTime == departureTime &&
        other.status == status &&
        other.maxCoRiders == maxCoRiders &&
        other.matchId == matchId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    pickup,
    dropoff,
    departureTime,
    status,
    maxCoRiders,
    matchId,
    createdAt,
  );
}
