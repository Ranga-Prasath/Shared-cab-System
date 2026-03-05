// -- Shared Cab System --
// Core model: Route Deviation Alert

import 'package:shared_cab/models/location_model.dart';

enum DeviationSeverity { low, medium, high }

class RouteDeviation {
  final String tripId;
  final double deviationDistanceKm;
  final LocationPoint expectedLocation;
  final LocationPoint actualLocation;
  final DateTime detectedAt;
  final DeviationSeverity severity;

  const RouteDeviation({
    required this.tripId,
    required this.deviationDistanceKm,
    required this.expectedLocation,
    required this.actualLocation,
    required this.detectedAt,
    required this.severity,
  });

  String get severityLabel {
    switch (severity) {
      case DeviationSeverity.low:
        return 'Minor';
      case DeviationSeverity.medium:
        return 'Moderate';
      case DeviationSeverity.high:
        return 'Critical';
    }
  }

  RouteDeviation copyWith({
    String? tripId,
    double? deviationDistanceKm,
    LocationPoint? expectedLocation,
    LocationPoint? actualLocation,
    DateTime? detectedAt,
    DeviationSeverity? severity,
  }) {
    return RouteDeviation(
      tripId: tripId ?? this.tripId,
      deviationDistanceKm: deviationDistanceKm ?? this.deviationDistanceKm,
      expectedLocation: expectedLocation ?? this.expectedLocation,
      actualLocation: actualLocation ?? this.actualLocation,
      detectedAt: detectedAt ?? this.detectedAt,
      severity: severity ?? this.severity,
    );
  }

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'deviationDistanceKm': deviationDistanceKm,
    'expectedLocation': expectedLocation.toJson(),
    'actualLocation': actualLocation.toJson(),
    'detectedAt': detectedAt.toIso8601String(),
    'severity': severity.name,
  };

  factory RouteDeviation.fromJson(Map<String, dynamic> json) {
    return RouteDeviation(
      tripId: json['tripId'] as String,
      deviationDistanceKm: (json['deviationDistanceKm'] as num).toDouble(),
      expectedLocation: LocationPoint.fromJson(
        json['expectedLocation'] as Map<String, dynamic>,
      ),
      actualLocation: LocationPoint.fromJson(
        json['actualLocation'] as Map<String, dynamic>,
      ),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      severity: DeviationSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => DeviationSeverity.low,
      ),
    );
  }

  @override
  String toString() {
    return 'RouteDeviation(tripId: $tripId, distanceKm: $deviationDistanceKm, severity: $severity, detectedAt: $detectedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteDeviation &&
        other.tripId == tripId &&
        other.deviationDistanceKm == deviationDistanceKm &&
        other.expectedLocation == expectedLocation &&
        other.actualLocation == actualLocation &&
        other.detectedAt == detectedAt &&
        other.severity == severity;
  }

  @override
  int get hashCode => Object.hash(
    tripId,
    deviationDistanceKm,
    expectedLocation,
    actualLocation,
    detectedAt,
    severity,
  );
}
