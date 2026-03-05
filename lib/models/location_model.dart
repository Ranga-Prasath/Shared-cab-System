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

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'landmark': landmark,
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      landmark: json['landmark'] as String?,
    );
  }

  @override
  String toString() {
    return 'LocationPoint(latitude: $latitude, longitude: $longitude, address: $address, landmark: $landmark)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationPoint &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address &&
        other.landmark == landmark;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, address, landmark);
}
