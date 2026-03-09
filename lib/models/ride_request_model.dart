// -- Shared Cab System --
// Core model: Ride Request

import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';

enum RideStatus { pending, requested, matched, declined, active, completed, cancelled }

class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final String userGender;
  final LocationPoint pickup;
  final LocationPoint dropoff;
  final DateTime departureTime;
  final RideStatus status;
  final int maxCoRiders;
  final String? matchId;
  final DateTime createdAt;
  final List<String> coRiderIds;
  final String? requesterId;
  final String? requesterName;
  final String? requesterGender;
  final String? requesterPickup;
  final String? requesterDropoff;

  const RideRequest({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userGender = '',
    required this.pickup,
    required this.dropoff,
    required this.departureTime,
    this.status = RideStatus.pending,
    this.maxCoRiders = 3,
    this.matchId,
    required this.createdAt,
    this.coRiderIds = const [],
    this.requesterId,
    this.requesterName,
    this.requesterGender,
    this.requesterPickup,
    this.requesterDropoff,
  });

  /// Whether this ride is during night hours (9 PM - 6 AM)
  bool get isNightRide {
    return isNightDateTime(departureTime);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userGender': userGender,
      'pickupLat': pickup.latitude,
      'pickupLng': pickup.longitude,
      'pickupAddress': pickup.address,
      'dropoffLat': dropoff.latitude,
      'dropoffLng': dropoff.longitude,
      'dropoffAddress': dropoff.address,
      'departureTime': departureTime.millisecondsSinceEpoch,
      'status': status.name,
      'maxCoRiders': maxCoRiders,
      'matchId': matchId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'coRiderIds': coRiderIds,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterGender': requesterGender,
      'requesterPickup': requesterPickup,
      'requesterDropoff': requesterDropoff,
    };
  }

  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userGender: map['userGender'] ?? '',
      pickup: LocationPoint(
        latitude: (map['pickupLat'] ?? 0).toDouble(),
        longitude: (map['pickupLng'] ?? 0).toDouble(),
        address: map['pickupAddress'] ?? '',
      ),
      dropoff: LocationPoint(
        latitude: (map['dropoffLat'] ?? 0).toDouble(),
        longitude: (map['dropoffLng'] ?? 0).toDouble(),
        address: map['dropoffAddress'] ?? '',
      ),
      departureTime: DateTime.fromMillisecondsSinceEpoch(
        map['departureTime'] ?? 0,
      ),
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.pending,
      ),
      maxCoRiders: map['maxCoRiders'] ?? 3,
      matchId: map['matchId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? 0,
      ),
      coRiderIds: List<String>.from(map['coRiderIds'] ?? []),
      requesterId: map['requesterId'],
      requesterName: map['requesterName'],
      requesterGender: map['requesterGender'],
      requesterPickup: map['requesterPickup'],
      requesterDropoff: map['requesterDropoff'],
    );
  }
}
