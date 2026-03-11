// -- Shared Cab System --
// Core model: Ride Request

import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';

<<<<<<< HEAD
enum RideStatus { pending, requested, acceptedWaiting, matched, declined, active, completed, cancelled }
=======
enum RideStatus {
  pending,
  requested,
  matched,
  declined,
  active,
  completed,
  cancelled,
}

class RidePickupStop {
  final String riderId;
  final String riderName;
  final double latitude;
  final double longitude;
  final String address;

  const RidePickupStop({
    required this.riderId,
    required this.riderName,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  RidePickupStop copyWith({
    String? riderId,
    String? riderName,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return RidePickupStop(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory RidePickupStop.fromMap(Map<String, dynamic> map) {
    return RidePickupStop(
      riderId: map['riderId']?.toString() ?? '',
      riderName: map['riderName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      address: map['address']?.toString() ?? '',
    );
  }
}

class RideRoutePoint {
  final double latitude;
  final double longitude;

  const RideRoutePoint({required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  factory RideRoutePoint.fromMap(Map<String, dynamic> map) {
    return RideRoutePoint(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
>>>>>>> 80114ce (Polish trip routing and demo verification)

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
  final double? requesterPickupLat;
  final double? requesterPickupLng;
  final double? cabLat;
  final double? cabLng;
  final double? cabBearing;
  final int? cabSegmentIndex;
  final double? cabSegmentProgress;
  final int? cabUpdatedAt;
  final bool waitForAnotherRider;
  final bool readyToProceed;
  final List<RidePickupStop> acceptedPickupStops;
  final List<RideRoutePoint> routePath;

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
    this.requesterPickupLat,
    this.requesterPickupLng,
    this.cabLat,
    this.cabLng,
    this.cabBearing,
    this.cabSegmentIndex,
    this.cabSegmentProgress,
    this.cabUpdatedAt,
    this.waitForAnotherRider = false,
    this.readyToProceed = false,
    this.acceptedPickupStops = const [],
    this.routePath = const [],
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
      'requesterPickupLat': requesterPickupLat,
      'requesterPickupLng': requesterPickupLng,
      'cabLat': cabLat,
      'cabLng': cabLng,
      'cabBearing': cabBearing,
      'cabSegmentIndex': cabSegmentIndex,
      'cabSegmentProgress': cabSegmentProgress,
      'cabUpdatedAt': cabUpdatedAt,
      'waitForAnotherRider': waitForAnotherRider,
      'readyToProceed': readyToProceed,
      'acceptedPickupStops': acceptedPickupStops
          .map((pickupStop) => pickupStop.toMap())
          .toList(),
      'routePath': routePath.map((point) => point.toMap()).toList(),
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      coRiderIds: List<String>.from(map['coRiderIds'] ?? []),
      requesterId: map['requesterId'],
      requesterName: map['requesterName'],
      requesterGender: map['requesterGender'],
      requesterPickup: map['requesterPickup'],
      requesterDropoff: map['requesterDropoff'],
      requesterPickupLat: (map['requesterPickupLat'] as num?)?.toDouble(),
      requesterPickupLng: (map['requesterPickupLng'] as num?)?.toDouble(),
      cabLat: (map['cabLat'] as num?)?.toDouble(),
      cabLng: (map['cabLng'] as num?)?.toDouble(),
      cabBearing: (map['cabBearing'] as num?)?.toDouble(),
      cabSegmentIndex: map['cabSegmentIndex'] as int?,
      cabSegmentProgress: (map['cabSegmentProgress'] as num?)?.toDouble(),
      cabUpdatedAt: map['cabUpdatedAt'] as int?,
      waitForAnotherRider: map['waitForAnotherRider'] as bool? ?? false,
      readyToProceed: map['readyToProceed'] as bool? ?? false,
      acceptedPickupStops:
          (map['acceptedPickupStops'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map(
                (item) =>
                    RidePickupStop.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
      routePath: (map['routePath'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => RideRoutePoint.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
