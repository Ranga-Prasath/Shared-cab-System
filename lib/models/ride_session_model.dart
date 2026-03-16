import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/trip_model.dart';

enum RideSessionEventType {
  sessionStarted,
  tripInProgress,
  destinationArrived,
  emergencyTriggered,
  safeArrivalConfirmed,
  sessionArchived,
}

class RideSessionEvent {
  final RideSessionEventType type;
  final DateTime occurredAt;
  final String summary;
  final Map<String, String> metadata;

  const RideSessionEvent({
    required this.type,
    required this.occurredAt,
    required this.summary,
    this.metadata = const {},
  });

  RideSessionEvent copyWith({
    RideSessionEventType? type,
    DateTime? occurredAt,
    String? summary,
    Map<String, String>? metadata,
  }) {
    return RideSessionEvent(
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      summary: summary ?? this.summary,
      metadata: metadata ?? this.metadata,
    );
  }
}

class RideSession {
  final String rideId;
  final String tripId;
  final List<String> riderIds;
  final RideStatus rideStatus;
  final TripStatus tripStatus;
  final String safeArrivalPin;
  final bool panicTriggered;
  final bool isArchived;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? archivedAt;
  final List<RideSessionEvent> events;

  const RideSession({
    required this.rideId,
    required this.tripId,
    required this.riderIds,
    required this.rideStatus,
    required this.tripStatus,
    required this.safeArrivalPin,
    required this.startedAt,
    this.panicTriggered = false,
    this.isArchived = false,
    this.endedAt,
    this.archivedAt,
    this.events = const [],
  });

  int get participantCount => riderIds.toSet().length;

  RideSession copyWith({
    List<String>? riderIds,
    RideStatus? rideStatus,
    TripStatus? tripStatus,
    String? safeArrivalPin,
    bool? panicTriggered,
    bool? isArchived,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? archivedAt,
    List<RideSessionEvent>? events,
  }) {
    return RideSession(
      rideId: rideId,
      tripId: tripId,
      riderIds: riderIds ?? this.riderIds,
      rideStatus: rideStatus ?? this.rideStatus,
      tripStatus: tripStatus ?? this.tripStatus,
      safeArrivalPin: safeArrivalPin ?? this.safeArrivalPin,
      startedAt: startedAt ?? this.startedAt,
      panicTriggered: panicTriggered ?? this.panicTriggered,
      isArchived: isArchived ?? this.isArchived,
      endedAt: endedAt ?? this.endedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      events: events ?? this.events,
    );
  }
}
