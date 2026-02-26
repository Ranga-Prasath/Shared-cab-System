import 'dart:convert';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'trip_map_math.dart';

class TripRouteBuilder {
  TripRouteBuilder._();

  static const _osrmHost = 'router.project-osrm.org';

  /// Fetches a road-following driving route. Falls back to mock route when
  /// network or API is unavailable.
  static Future<List<LatLng>> buildRoadFirstRoute(
    LatLng start,
    LatLng end, {
    int minPoints = 120,
  }) async {
    final roadRoute = await _fetchOsrmRoute(
      start,
      end,
      timeout: const Duration(seconds: 4),
    );

    if (roadRoute == null || roadRoute.length < 2) {
      return buildHighFidelityMockRoute(start, end, minPoints: minPoints);
    }

    final densified = _densifyIfNeeded(roadRoute, minPoints: minPoints);
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
    final amp = math.min(0.0015, norm * 0.18);

    for (var i = 0; i <= count; i++) {
      final t = i / count;

      // Multi-frequency offset gives a more road-like shape than one curve.
      final wave1 = math.sin(t * math.pi * 2.2) * amp;
      final wave2 = math.sin(t * math.pi * 6.0) * amp * 0.22;
      final wave3 = math.cos(t * math.pi * 3.5) * amp * 0.15;
      final offset = wave1 + wave2 + wave3;

      final lat = start.latitude + deltaLat * t + perpLat * offset;
      final lng = start.longitude + deltaLng * t + perpLng * offset;
      points.add(LatLng(lat, lng));
    }

    points[0] = start;
    points[points.length - 1] = end;
    return points;
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
}
