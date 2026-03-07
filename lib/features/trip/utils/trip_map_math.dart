import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class TripMapMath {
  TripMapMath._();

  static LatLng lerpLatLng(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  static double bearingBetween(LatLng from, LatLng to) {
    final fromLat = _toRadians(from.latitude);
    final fromLng = _toRadians(from.longitude);
    final toLat = _toRadians(to.latitude);
    final toLng = _toRadians(to.longitude);

    final y = math.sin(toLng - fromLng) * math.cos(toLat);
    final x =
        math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(toLng - fromLng);

    final bearing = _toDegrees(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  static double lerpBearing(double from, double to, double t) {
    final delta = ((to - from + 540) % 360) - 180;
    return (from + delta * t + 360) % 360;
  }

  static double routeDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;
    var distance = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      distance += _haversineKm(points[i], points[i + 1]);
    }
    return distance;
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180);
  static double _toDegrees(double radians) => radians * (180 / math.pi);
}
