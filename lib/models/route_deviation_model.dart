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
}
