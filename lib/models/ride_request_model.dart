// -- Shared Cab System --
// Core model: Ride Request

import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/core/constants/app_constants.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/models/ride_preferences_model.dart';

enum RideStatus {
  pending,
  requested,
  matched,
  declined,
  active,
  completed,
  cancelled,
}

enum RideJoinRequestStatus { pending, accepted, declined, cancelled, expired }

class RideJoinRequest {
  final String requesterId;
  final String requesterName;
  final String requesterGender;
  final String requesterPickup;
  final String requesterDropoff;
  final double? requesterPickupLat;
  final double? requesterPickupLng;
  final RideJoinRequestStatus status;
  final DateTime requestedAt;
  final DateTime updatedAt;
  final DateTime statusUpdatedAt;
  final DateTime? requestExpiryAt;
  final DateTime? resolvedAt;
  final String? statusReason;
  final String? requestClientReasonCode;
  final int flowVersion;

  const RideJoinRequest({
    required this.requesterId,
    this.requesterName = '',
    this.requesterGender = '',
    this.requesterPickup = '',
    this.requesterDropoff = '',
    this.requesterPickupLat,
    this.requesterPickupLng,
    this.status = RideJoinRequestStatus.pending,
    required this.requestedAt,
    required this.updatedAt,
    DateTime? statusUpdatedAt,
    this.requestExpiryAt,
    this.resolvedAt,
    this.statusReason,
    this.requestClientReasonCode,
    this.flowVersion = AppConstants.requestFlowVersion,
  }) : statusUpdatedAt = statusUpdatedAt ?? updatedAt;

  bool isExpiredAt(DateTime now) {
    if (status != RideJoinRequestStatus.pending) return false;
    final expiry = requestExpiryAt;
    if (expiry == null) return false;
    return now.isAfter(expiry);
  }

  RideJoinRequest copyWith({
    String? requesterId,
    String? requesterName,
    String? requesterGender,
    String? requesterPickup,
    String? requesterDropoff,
    double? requesterPickupLat,
    double? requesterPickupLng,
    RideJoinRequestStatus? status,
    DateTime? requestedAt,
    DateTime? updatedAt,
    DateTime? statusUpdatedAt,
    DateTime? requestExpiryAt,
    DateTime? resolvedAt,
    String? statusReason,
    String? requestClientReasonCode,
    int? flowVersion,
    bool clearResolvedAt = false,
    bool clearStatusReason = false,
    bool clearRequestExpiryAt = false,
    bool clearRequestClientReasonCode = false,
  }) {
    return RideJoinRequest(
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterGender: requesterGender ?? this.requesterGender,
      requesterPickup: requesterPickup ?? this.requesterPickup,
      requesterDropoff: requesterDropoff ?? this.requesterDropoff,
      requesterPickupLat: requesterPickupLat ?? this.requesterPickupLat,
      requesterPickupLng: requesterPickupLng ?? this.requesterPickupLng,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      requestExpiryAt: clearRequestExpiryAt
          ? null
          : (requestExpiryAt ?? this.requestExpiryAt),
      resolvedAt: clearResolvedAt ? null : (resolvedAt ?? this.resolvedAt),
      statusReason: clearStatusReason
          ? null
          : (statusReason ?? this.statusReason),
      requestClientReasonCode: clearRequestClientReasonCode
          ? null
          : (requestClientReasonCode ?? this.requestClientReasonCode),
      flowVersion: flowVersion ?? this.flowVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterGender': requesterGender,
      'requesterPickup': requesterPickup,
      'requesterDropoff': requesterDropoff,
      'requesterPickupLat': requesterPickupLat,
      'requesterPickupLng': requesterPickupLng,
      'status': status.name,
      'requestedAt': requestedAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'statusUpdatedAt': statusUpdatedAt.millisecondsSinceEpoch,
      'requestExpiryAt': requestExpiryAt?.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'statusReason': statusReason,
      'requestClientReasonCode': requestClientReasonCode,
      'flowVersion': flowVersion,
    };
  }

  factory RideJoinRequest.fromMap(Map<String, dynamic> map) {
    return RideJoinRequest(
      requesterId: map['requesterId']?.toString() ?? '',
      requesterName: map['requesterName']?.toString() ?? '',
      requesterGender: map['requesterGender']?.toString() ?? '',
      requesterPickup: map['requesterPickup']?.toString() ?? '',
      requesterDropoff: map['requesterDropoff']?.toString() ?? '',
      requesterPickupLat: (map['requesterPickupLat'] as num?)?.toDouble(),
      requesterPickupLng: (map['requesterPickupLng'] as num?)?.toDouble(),
      status: RideJoinRequestStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => RideJoinRequestStatus.pending,
      ),
      requestedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['requestedAt'] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ??
            (map['requestedAt'] as num?)?.toInt() ??
            0,
      ),
      statusUpdatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['statusUpdatedAt'] as num?)?.toInt() ??
            (map['updatedAt'] as num?)?.toInt() ??
            (map['requestedAt'] as num?)?.toInt() ??
            0,
      ),
      requestExpiryAt: (map['requestExpiryAt'] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['requestExpiryAt'] as num).toInt(),
            ),
      resolvedAt: (map['resolvedAt'] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['resolvedAt'] as num).toInt(),
            ),
      statusReason: map['statusReason']?.toString(),
      requestClientReasonCode: map['requestClientReasonCode']?.toString(),
      flowVersion:
          (map['flowVersion'] as num?)?.toInt() ??
          AppConstants.requestFlowVersion,
    );
  }
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
  final List<RideJoinRequest> joinRequests;
  final double? cabLat;
  final double? cabLng;
  final double? cabBearing;
  final int? cabSegmentIndex;
  final double? cabSegmentProgress;
  final int? cabUpdatedAt;
  final bool waitForAnotherRider;
  final bool readyToProceed;
  final String safeArrivalPin;
  final List<RidePickupStop> acceptedPickupStops;
  final List<RideRoutePoint> routePath;
  final RidePreferences preferenceSnapshot;

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
    this.joinRequests = const [],
    this.cabLat,
    this.cabLng,
    this.cabBearing,
    this.cabSegmentIndex,
    this.cabSegmentProgress,
    this.cabUpdatedAt,
    this.waitForAnotherRider = false,
    this.readyToProceed = false,
    this.safeArrivalPin = '',
    this.acceptedPickupStops = const [],
    this.routePath = const [],
    this.preferenceSnapshot = const RidePreferences(),
  });

  /// Whether this ride is during night hours (9 PM - 6 AM)
  bool get isNightRide {
    return isNightDateTime(departureTime);
  }

  List<RideJoinRequest> get pendingJoinRequests {
    final pending = joinRequests
        .where(
          (request) =>
              request.status == RideJoinRequestStatus.pending &&
              !request.isExpiredAt(DateTime.now()),
        )
        .toList();
    pending.sort((left, right) => left.requestedAt.compareTo(right.requestedAt));
    return pending;
  }

  RideJoinRequest? get activeJoinRequest {
    final pending = pendingJoinRequests;
    return pending.isEmpty ? null : pending.first;
  }

  RideJoinRequest? joinRequestFor(String requesterId) {
    for (final request in joinRequests) {
      if (request.requesterId == requesterId) {
        return request;
      }
    }
    return null;
  }

  RideRequest copyWith({
    RideStatus? status,
    List<String>? coRiderIds,
    List<RideJoinRequest>? joinRequests,
    bool? waitForAnotherRider,
    bool? readyToProceed,
    String? safeArrivalPin,
    List<RidePickupStop>? acceptedPickupStops,
    List<RideRoutePoint>? routePath,
    RidePreferences? preferenceSnapshot,
  }) {
    return RideRequest(
      id: id,
      userId: userId,
      userName: userName,
      userGender: userGender,
      pickup: pickup,
      dropoff: dropoff,
      departureTime: departureTime,
      status: status ?? this.status,
      maxCoRiders: maxCoRiders,
      matchId: matchId,
      createdAt: createdAt,
      coRiderIds: coRiderIds ?? this.coRiderIds,
      joinRequests: joinRequests ?? this.joinRequests,
      cabLat: cabLat,
      cabLng: cabLng,
      cabBearing: cabBearing,
      cabSegmentIndex: cabSegmentIndex,
      cabSegmentProgress: cabSegmentProgress,
      cabUpdatedAt: cabUpdatedAt,
      waitForAnotherRider: waitForAnotherRider ?? this.waitForAnotherRider,
      readyToProceed: readyToProceed ?? this.readyToProceed,
      safeArrivalPin: safeArrivalPin ?? this.safeArrivalPin,
      acceptedPickupStops: acceptedPickupStops ?? this.acceptedPickupStops,
      routePath: routePath ?? this.routePath,
      preferenceSnapshot: preferenceSnapshot ?? this.preferenceSnapshot,
    );
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
      'joinRequests': joinRequests.map((request) => request.toMap()).toList(),
      'cabLat': cabLat,
      'cabLng': cabLng,
      'cabBearing': cabBearing,
      'cabSegmentIndex': cabSegmentIndex,
      'cabSegmentProgress': cabSegmentProgress,
      'cabUpdatedAt': cabUpdatedAt,
      'waitForAnotherRider': waitForAnotherRider,
      'readyToProceed': readyToProceed,
      'safeArrivalPin': safeArrivalPin,
      'acceptedPickupStops': acceptedPickupStops
          .map((pickupStop) => pickupStop.toMap())
          .toList(),
      'routePath': routePath.map((point) => point.toMap()).toList(),
      'preferenceSnapshot': preferenceSnapshot.toMap(),
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
      joinRequests: _joinRequestsFromMap(map),
      cabLat: (map['cabLat'] as num?)?.toDouble(),
      cabLng: (map['cabLng'] as num?)?.toDouble(),
      cabBearing: (map['cabBearing'] as num?)?.toDouble(),
      cabSegmentIndex: map['cabSegmentIndex'] as int?,
      cabSegmentProgress: (map['cabSegmentProgress'] as num?)?.toDouble(),
      cabUpdatedAt: map['cabUpdatedAt'] as int?,
      waitForAnotherRider: map['waitForAnotherRider'] as bool? ?? false,
      readyToProceed: map['readyToProceed'] as bool? ?? false,
      safeArrivalPin: map['safeArrivalPin']?.toString() ?? '',
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
      preferenceSnapshot: RidePreferences.fromMap(
        Map<String, dynamic>.from(
          map['preferenceSnapshot'] as Map<dynamic, dynamic>? ?? const {},
        ),
      ),
    );
  }

  static List<RideJoinRequest> _joinRequestsFromMap(Map<String, dynamic> map) {
    final rawRequests = map['joinRequests'] as List<dynamic>?;
    if (rawRequests != null) {
      return rawRequests
          .whereType<Map>()
          .map((item) => RideJoinRequest.fromMap(Map<String, dynamic>.from(item)))
          .where((request) => request.requesterId.isNotEmpty)
          .toList();
    }

    final legacyRequesterId = map['requesterId']?.toString() ?? '';
    if (legacyRequesterId.isEmpty) {
      return const [];
    }

    final legacyStatus = RideJoinRequestStatus.values.firstWhere(
      (value) => value.name == map['status'],
      orElse: () => RideJoinRequestStatus.pending,
    );
    final requestedAt = DateTime.fromMillisecondsSinceEpoch(
      map['createdAt'] ?? 0,
    );

    return [
      RideJoinRequest(
        requesterId: legacyRequesterId,
        requesterName: map['requesterName']?.toString() ?? '',
        requesterGender: map['requesterGender']?.toString() ?? '',
        requesterPickup: map['requesterPickup']?.toString() ?? '',
        requesterDropoff: map['requesterDropoff']?.toString() ?? '',
        requesterPickupLat: (map['requesterPickupLat'] as num?)?.toDouble(),
        requesterPickupLng: (map['requesterPickupLng'] as num?)?.toDouble(),
        status: legacyStatus,
        requestedAt: requestedAt,
        updatedAt: requestedAt,
        statusUpdatedAt: requestedAt,
        resolvedAt: legacyStatus == RideJoinRequestStatus.pending
            ? null
            : requestedAt,
        requestClientReasonCode: legacyStatus == RideJoinRequestStatus.pending
            ? null
            : legacyStatus.name,
        flowVersion: AppConstants.requestFlowVersion,
      ),
    ];
  }
}
