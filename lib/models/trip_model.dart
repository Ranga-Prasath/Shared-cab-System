// -- Shared Cab System --
// Core model: Trip

import 'package:flutter/foundation.dart';

enum TripStatus {
  waitingForPickup,
  inProgress,
  arrivedDestination,
  completed,
  emergency,
}

class Trip {
  final String id;
  final String matchId;
  final List<String> riderIds;
  final TripStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? safeArrivalPin;
  final bool isPinConfirmed;
  final bool isNightTrip;
  final bool panicTriggered;
  final double? tripDistanceKm;
  final double? farePerPerson;

  const Trip({
    required this.id,
    required this.matchId,
    required this.riderIds,
    this.status = TripStatus.waitingForPickup,
    required this.startTime,
    this.endTime,
    this.safeArrivalPin,
    this.isPinConfirmed = false,
    this.isNightTrip = false,
    this.panicTriggered = false,
    this.tripDistanceKm,
    this.farePerPerson,
  });

  Trip copyWith({
    String? id,
    String? matchId,
    List<String>? riderIds,
    TripStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? safeArrivalPin,
    bool? isPinConfirmed,
    bool? isNightTrip,
    bool? panicTriggered,
    double? tripDistanceKm,
    double? farePerPerson,
  }) {
    return Trip(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      riderIds: riderIds ?? this.riderIds,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      safeArrivalPin: safeArrivalPin ?? this.safeArrivalPin,
      isPinConfirmed: isPinConfirmed ?? this.isPinConfirmed,
      isNightTrip: isNightTrip ?? this.isNightTrip,
      panicTriggered: panicTriggered ?? this.panicTriggered,
      tripDistanceKm: tripDistanceKm ?? this.tripDistanceKm,
      farePerPerson: farePerPerson ?? this.farePerPerson,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchId': matchId,
    'riderIds': riderIds,
    'status': status.name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'safeArrivalPin': safeArrivalPin,
    'isPinConfirmed': isPinConfirmed,
    'isNightTrip': isNightTrip,
    'panicTriggered': panicTriggered,
    'tripDistanceKm': tripDistanceKm,
    'farePerPerson': farePerPerson,
  };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final riders = json['riderIds'] as List<dynamic>? ?? const [];
    return Trip(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      riderIds: riders.map((item) => item.toString()).toList(),
      status: TripStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => TripStatus.waitingForPickup,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: (json['endTime'] as String?) == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      safeArrivalPin: json['safeArrivalPin'] as String?,
      isPinConfirmed: json['isPinConfirmed'] as bool? ?? false,
      isNightTrip: json['isNightTrip'] as bool? ?? false,
      panicTriggered: json['panicTriggered'] as bool? ?? false,
      tripDistanceKm: (json['tripDistanceKm'] as num?)?.toDouble(),
      farePerPerson: (json['farePerPerson'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'Trip(id: $id, status: $status, riders: ${riderIds.length}, isNightTrip: $isNightTrip, panicTriggered: $panicTriggered)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip &&
        other.id == id &&
        other.matchId == matchId &&
        listEquals(other.riderIds, riderIds) &&
        other.status == status &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.safeArrivalPin == safeArrivalPin &&
        other.isPinConfirmed == isPinConfirmed &&
        other.isNightTrip == isNightTrip &&
        other.panicTriggered == panicTriggered &&
        other.tripDistanceKm == tripDistanceKm &&
        other.farePerPerson == farePerPerson;
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchId,
    Object.hashAll(riderIds),
    status,
    startTime,
    endTime,
    safeArrivalPin,
    isPinConfirmed,
    isNightTrip,
    panicTriggered,
    tripDistanceKm,
    farePerPerson,
  );
}
