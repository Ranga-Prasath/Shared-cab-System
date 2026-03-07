// -- Shared Cab System --
// Core model: Trip

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
    TripStatus? status,
    DateTime? endTime,
    String? safeArrivalPin,
    bool? isPinConfirmed,
    bool? panicTriggered,
  }) {
    return Trip(
      id: id,
      matchId: matchId,
      riderIds: riderIds,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      safeArrivalPin: safeArrivalPin ?? this.safeArrivalPin,
      isPinConfirmed: isPinConfirmed ?? this.isPinConfirmed,
      isNightTrip: isNightTrip,
      panicTriggered: panicTriggered ?? this.panicTriggered,
      tripDistanceKm: tripDistanceKm,
      farePerPerson: farePerPerson,
    );
  }
}
