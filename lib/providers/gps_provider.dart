// -- Shared Cab System --
// GPS Location Provider — streams real device location

import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service class for GPS operations
class GpsService {
  GpsService._();

  static const Duration defaultAcquisitionTimeout = Duration(seconds: 3);

  /// Check and request location permissions
  static Future<bool> ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get the current position once
  static Future<Position?> getCurrentPosition({
    Duration timeout = defaultAcquisitionTimeout,
  }) async {
    try {
      final ok = await ensurePermission();
      if (!ok) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  /// Start streaming position updates
  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Minimum 5m movement to fire
      ),
    );
  }
}
