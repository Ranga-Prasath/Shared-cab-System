// -- Shared Cab System --
// Core model: Location Point

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

  /// Simple straight-line distance estimate (demo only)
  double distanceTo(LocationPoint other) {
    final dLat = (other.latitude - latitude).abs();
    final dLon = (other.longitude - longitude).abs();
    return (dLat + dLon) * 111; // rough km per degree
  }
}
