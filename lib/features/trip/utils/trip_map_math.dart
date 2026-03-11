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

  static double distanceKmBetween(LatLng a, LatLng b) {
    return _haversineKm(a, b);
  }

  static double routeScalarFromProgress({
    required double overallProgress,
    required int pointCount,
  }) {
    if (pointCount < 2) return 0;
    final maxScalar = (pointCount - 1).toDouble();
    return (overallProgress.clamp(0.0, 1.0) * maxScalar)
        .clamp(0.0, maxScalar)
        .toDouble();
  }

  static double routeScalarFromSegment({
    required int segmentIndex,
    required double segmentProgress,
    required int pointCount,
  }) {
    if (pointCount < 2) return 0;
    final safeSegmentIndex = segmentIndex.clamp(0, pointCount - 2);
    final safeSegmentProgress = segmentProgress.clamp(0.0, 1.0);
    return (safeSegmentIndex + safeSegmentProgress)
        .clamp(0.0, (pointCount - 1).toDouble())
        .toDouble();
  }

  static TripRouteFrame routeFrameFromScalar({
    required double routeScalar,
    required int pointCount,
  }) {
    if (pointCount < 2) {
      return const TripRouteFrame(
        segmentIndex: 0,
        segmentProgress: 0,
        overallProgress: 0,
      );
    }

    final maxScalar = (pointCount - 1).toDouble();
    final safeScalar = routeScalar.clamp(0.0, maxScalar).toDouble();
    final segmentIndex = safeScalar >= maxScalar
        ? pointCount - 2
        : safeScalar.floor();
    final segmentProgress = safeScalar >= maxScalar
        ? 1.0
        : (safeScalar - segmentIndex).clamp(0.0, 1.0).toDouble();

    return TripRouteFrame(
      segmentIndex: segmentIndex,
      segmentProgress: segmentProgress,
      overallProgress: (safeScalar / maxScalar).clamp(0.0, 1.0).toDouble(),
    );
  }

  static Duration recommendedRemoteSyncDuration({
    int? previousUpdateAtMs,
    int? currentUpdateAtMs,
    Duration fallback = const Duration(milliseconds: 1450),
  }) {
    if (previousUpdateAtMs == null || currentUpdateAtMs == null) {
      return fallback;
    }

    final diffMs = currentUpdateAtMs - previousUpdateAtMs;
    if (diffMs <= 0) return fallback;
    final clampedMs = diffMs.clamp(400, 1600);
    return Duration(milliseconds: clampedMs);
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

class TripRouteFrame {
  final int segmentIndex;
  final double segmentProgress;
  final double overallProgress;

  const TripRouteFrame({
    required this.segmentIndex,
    required this.segmentProgress,
    required this.overallProgress,
  });
}
