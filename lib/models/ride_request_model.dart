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
}
