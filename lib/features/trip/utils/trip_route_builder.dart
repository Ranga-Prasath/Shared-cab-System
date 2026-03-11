// SPEC: Destination-Driven Pickup Ordering
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WHAT IT DOES:
//   Orders shared-ride pickups so the cab starts at the rider farthest from
//   the destination, then keeps moving toward the destination.
//
// DATA OBJECTS:
//   Pickup waypoint - LatLng for each rider pickup
//   Destination - LatLng shared drop-off for the trip
//
// OPERATIONS:
//   buildRoadFirstRoute: point A/B -> road-shaped route
//   routeOverlapPercent: route A/B -> overlap percentage
//   orderPickupWaypoints: host + co-riders + destination -> pickup order
//
// EDGE CASES HANDLED:
//   • duplicate pickup coordinates collapse into one stop
//   • single-pickup rides still return one valid pickup
//   • equal-distance pickups keep input order for deterministic demos
//
// ASSUMPTIONS MADE:
//   • the destination is shared across the riders in a shared trip
//   • "logical" demo routing means farther-from-destination riders are picked
//     first instead of always starting at the host pickup
//
// DONE WHEN:
//   pickup ordering is stable, farthest-first, duplicate-safe, and trip tests
//   verify the cab approaches the destination through each rider in order.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'trip_map_math.dart';

class TripRouteBuilder {
  TripRouteBuilder._();

  static const _osrmHost = 'router.project-osrm.org';
  static const _maxJumpMeters = 1500.0;
  static const Distance _distance = Distance();
  static const _matchCorridorMeters = 1200.0;

  /// Fetches a road-following driving route. Falls back to mock route when
  /// network or API is unavailable.
  static Future<List<LatLng>> buildRoadFirstRoute(
    LatLng start,
    LatLng end, {
    int minPoints = 120,
  }) async {
    final roadRoute = await _fetchOsrmRouteWithRetries(start, end);

    if (roadRoute == null || roadRoute.length < 2) {
      return buildHighFidelityMockRoute(start, end, minPoints: minPoints);
    }

    final sanitized = _sanitizeRoadRoute(roadRoute);
    if (sanitized.length < 2) {
      return buildHighFidelityMockRoute(start, end, minPoints: minPoints);
    }

    final densified = _densifyIfNeeded(sanitized, minPoints: minPoints);
    densified[0] = start;
    densified[densified.length - 1] = end;
    return densified;
  }

  /// Demo route with 100+ points that feels road-snapped.
  static List<LatLng> buildHighFidelityMockRoute(
    LatLng start,
    LatLng end, {
    int minPoints = 120,
  }) {
    final count = minPoints < 100 ? 100 : minPoints;
    final points = <LatLng>[];

    final deltaLat = end.latitude - start.latitude;
    final deltaLng = end.longitude - start.longitude;
    final norm = math.max(deltaLat.abs() + deltaLng.abs(), 0.00001);
    final perpLat = -deltaLng / norm;
    final perpLng = deltaLat / norm;
    final amp = math.min(0.00055, norm * 0.08);

    for (var i = 0; i <= count; i++) {
      final t = i / count;
      final smoothT = t * t * (3 - (2 * t));

      // Monotonic fallback with a single gentle bend to avoid loops.
      final offset = math.sin(smoothT * math.pi) * amp;

      final lat = start.latitude + deltaLat * smoothT + perpLat * offset;
      final lng = start.longitude + deltaLng * smoothT + perpLng * offset;
      points.add(LatLng(lat, lng));
    }

    points[0] = start;
    points[points.length - 1] = end;
    return points;
  }

  static Future<List<LatLng>?> _fetchOsrmRouteWithRetries(
    LatLng start,
    LatLng end,
  ) async {
    const attempts = [
      Duration(seconds: 4),
      Duration(seconds: 6),
      Duration(seconds: 8),
    ];
    for (final timeout in attempts) {
      final route = await _fetchOsrmRoute(start, end, timeout: timeout);
      if (route != null && route.length >= 2) return route;
    }
    return null;
  }

  /// Plug real Google Directions encoded polyline here when ready.
  static List<LatLng> buildFromEncodedPolyline(String encoded) {
    final result = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var value = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        value |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLat = ((value & 1) != 0 ? ~(value >> 1) : (value >> 1));
      lat += deltaLat;

      shift = 0;
      value = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        value |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLng = ((value & 1) != 0 ? ~(value >> 1) : (value >> 1));
      lng += deltaLng;

      result.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return result;
  }

  static double estimatedDistanceKm(List<LatLng> points) {
    return TripMapMath.routeDistanceKm(points);
  }

  static List<LatLng> compressRouteForStorage(
    List<LatLng> points, {
    int maxPoints = 60,
  }) {
    if (points.length <= 2) return [...points];
    if (points.length <= maxPoints) return [...points];

    final sampled = <LatLng>[];
    for (var i = 0; i < maxPoints; i++) {
      final t = i / (maxPoints - 1);
      final index = (t * (points.length - 1)).round();
      final point = points[index];
      if (!_containsApproxPoint(sampled, point)) {
        sampled.add(point);
      }
    }

    if (sampled.length == 1) {
      sampled.add(points.last);
    }
    return sampled;
  }

  static double routeOverlapPercent(
    List<LatLng> routeA,
    List<LatLng> routeB, {
    double corridorMeters = _matchCorridorMeters,
  }) {
    if (routeA.length < 2 || routeB.length < 2) return 0;

    final sampleRoute = routeA.length <= routeB.length ? routeA : routeB;
    final compareRoute = identical(sampleRoute, routeA) ? routeB : routeA;

    var matchedPoints = 0;
    for (final point in sampleRoute) {
      if (_minDistanceMetersToRoute(point, compareRoute) <= corridorMeters) {
        matchedPoints++;
      }
    }

    return (matchedPoints / sampleRoute.length) * 100;
  }

  static bool routesShareCorridor(
    List<LatLng> routeA,
    List<LatLng> routeB, {
    double thresholdPercent = 35,
    double corridorMeters = _matchCorridorMeters,
  }) {
    return routeOverlapPercent(
          routeA,
          routeB,
          corridorMeters: corridorMeters,
        ) >=
        thresholdPercent;
  }

  static double pointDistanceToRouteKm(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;
    return _minDistanceMetersToRoute(point, route) / 1000;
  }

  static List<LatLng> orderPickupWaypoints({
    required LatLng hostPickup,
    required List<LatLng> coRiderPickups,
    required LatLng destination,
  }) {
    final uniquePickups = <LatLng>[];

    void addPickupIfUnique(LatLng pickup) {
      if (_containsApproxPoint(uniquePickups, pickup)) return;
      uniquePickups.add(pickup);
    }

    addPickupIfUnique(hostPickup);
    for (final pickup in coRiderPickups) {
      addPickupIfUnique(pickup);
    }

    final candidates = <_OrderedPickupCandidate>[
      for (var index = 0; index < uniquePickups.length; index++)
        _OrderedPickupCandidate(
          point: uniquePickups[index],
          inputIndex: index,
          destinationMeters: _distance.distance(uniquePickups[index], destination),
        ),
    ];

    // WHY: for the demo, the cab should start at the pickup farthest from the
    // destination and then keep moving inward toward the shared drop-off.
    candidates.sort((a, b) {
      final distanceOrder = b.destinationMeters.compareTo(a.destinationMeters);
      if (distanceOrder != 0) return distanceOrder;
      return a.inputIndex.compareTo(b.inputIndex);
    });

    return candidates.map((candidate) => candidate.point).toList();
  }

  static Future<List<LatLng>?> _fetchOsrmRoute(
    LatLng start,
    LatLng end, {
    required Duration timeout,
  }) async {
    final path =
        '/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}';
    final uri = Uri.https(_osrmHost, path, {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': 'false',
    });

    try {
      final response = await http.get(uri).timeout(timeout);
      if (response.statusCode != 200) return null;

      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      final routes = jsonMap['routes'];
      if (routes is! List || routes.isEmpty) return null;

      final firstRoute = routes.first;
      if (firstRoute is! Map<String, dynamic>) return null;
      final geometry = firstRoute['geometry'];
      if (geometry is! Map<String, dynamic>) return null;
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.isEmpty) return null;

      final points = <LatLng>[];
      for (final item in coordinates) {
        if (item is! List || item.length < 2) continue;
        final lon = (item[0] as num?)?.toDouble();
        final lat = (item[1] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        points.add(LatLng(lat, lon));
      }
      return points.length >= 2 ? points : null;
    } catch (_) {
      return null;
    }
  }

  static List<LatLng> _densifyIfNeeded(
    List<LatLng> source, {
    required int minPoints,
  }) {
    if (source.length >= minPoints) return [...source];
    if (source.length < 2) return [...source];

    final segmentCount = source.length - 1;
    final neededExtra = minPoints - source.length;
    final stepsPerSegment = (neededExtra / segmentCount).ceil();

    final dense = <LatLng>[];
    for (var i = 0; i < source.length - 1; i++) {
      final a = source[i];
      final b = source[i + 1];
      dense.add(a);

      for (var j = 1; j <= stepsPerSegment; j++) {
        final t = j / (stepsPerSegment + 1);
        dense.add(TripMapMath.lerpLatLng(a, b, t));
      }
    }
    dense.add(source.last);
    return dense;
  }

  static List<LatLng> _sanitizeRoadRoute(List<LatLng> source) {
    if (source.length < 2) return [...source];
    final sanitized = <LatLng>[source.first];

    for (var i = 1; i < source.length; i++) {
      final previous = sanitized.last;
      final current = source[i];
      final jumpMeters = _distance.distance(previous, current);
      if (jumpMeters <= _maxJumpMeters) {
        sanitized.add(current);
      }
    }
    return sanitized;
  }

  static bool _containsApproxPoint(List<LatLng> points, LatLng candidate) {
    const epsilon = 0.0002;
    return points.any(
      (point) =>
          (point.latitude - candidate.latitude).abs() < epsilon &&
          (point.longitude - candidate.longitude).abs() < epsilon,
    );
  }

  static double _minDistanceMetersToRoute(LatLng point, List<LatLng> route) {
    var minDistanceMeters = double.infinity;

    for (final routePoint in route) {
      final distanceMeters = _distance.distance(point, routePoint);
      if (distanceMeters < minDistanceMeters) {
        minDistanceMeters = distanceMeters;
      }
    }

    return minDistanceMeters;
  }
}

class _OrderedPickupCandidate {
  final LatLng point;
  final int inputIndex;
  final double destinationMeters;

  const _OrderedPickupCandidate({
    required this.point,
    required this.inputIndex,
    required this.destinationMeters,
  });
}
