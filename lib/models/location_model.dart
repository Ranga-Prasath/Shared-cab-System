// -- Shared Cab System --
// Core model: Location Point

import 'dart:math' as math;

class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
  });

  /// Great-circle distance in kilometers.
  double distanceTo(LocationPoint other) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(other.latitude);

    final h =
        _sinSquared(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * _sinSquared(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180);

  static double _sinSquared(double value) {
    final sine = math.sin(value);
    return sine * sine;
  }
}
