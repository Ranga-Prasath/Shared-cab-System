// -- Shared Cab System --
// Geocoding Service — reverse geocode & place search via Nominatim (OSM)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_cab/models/location_model.dart';

class GeocodingService {
  GeocodingService._();

  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _userAgent = 'SharedCabApp/1.0 (demo)';

  // Rate-limit: Nominatim allows max 1 request/sec
  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> _throttle() async {
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < const Duration(milliseconds: 1100)) {
      await Future.delayed(const Duration(milliseconds: 1100) - elapsed);
    }
    _lastRequest = DateTime.now();
  }

  /// Convert lat/lng to a human-readable address string.
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      await _throttle();
      final uri = Uri.parse(
        '$_baseUrl/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (response.statusCode != 200) return _fallbackAddress(lat, lng);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      if (address == null) return data['display_name'] ?? _fallbackAddress(lat, lng);

      // Build a short, clean address
      final parts = <String>[];
      final road = address['road'] ?? address['pedestrian'] ?? address['footway'];
      if (road != null) parts.add(road.toString());

      final area = address['suburb'] ??
          address['neighbourhood'] ??
          address['village'] ??
          address['town'];
      if (area != null) parts.add(area.toString());

      final city = address['city'] ??
          address['state_district'] ??
          address['county'];
      if (city != null && city != area) parts.add(city.toString());

      if (parts.isEmpty) {
        return data['display_name'] ?? _fallbackAddress(lat, lng);
      }
      return parts.join(', ');
    } catch (_) {
      return _fallbackAddress(lat, lng);
    }
  }

  /// Search for places by text query — returns up to 5 results.
  static Future<List<LocationPoint>> searchPlaces(String query) async {
    if (query.trim().length < 3) return const [];

    try {
      await _throttle();
      final uri = Uri.parse(
        '$_baseUrl/search?format=json&q=${Uri.encodeComponent(query)}'
        '&limit=5&addressdetails=1&countrycodes=in',
      );
      final response = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (response.statusCode != 200) return const [];

      final data = json.decode(response.body) as List;
      return data.map<LocationPoint>((item) {
        final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0;
        final lng = double.tryParse(item['lon']?.toString() ?? '') ?? 0;
        final displayName = item['display_name']?.toString() ?? '';

        // Shorten the display name for the UI
        final nameParts = displayName.split(', ');
        final shortName = nameParts.take(3).join(', ');

        return LocationPoint(
          latitude: lat,
          longitude: lng,
          address: shortName,
          landmark: nameParts.length > 3 ? nameParts[0] : null,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Reverse-geocode and return a full LocationPoint.
  static Future<LocationPoint> getLocationPoint(double lat, double lng) async {
    final address = await reverseGeocode(lat, lng);
    return LocationPoint(latitude: lat, longitude: lng, address: address);
  }

  static String _fallbackAddress(double lat, double lng) {
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }
}
