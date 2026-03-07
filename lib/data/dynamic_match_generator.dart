// -- Shared Cab System --
// Dynamic Match Generator — creates route-aware co-riders using real geocoded addresses

import 'dart:math';
import 'package:shared_cab/core/services/geocoding_service.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/match_model.dart';

class DynamicMatchGenerator {
  DynamicMatchGenerator._();

  static final _random = Random();

  static const _firstNames = [
    'Arun', 'Priya', 'Karthik', 'Divya', 'Rahul',
    'Sneha', 'Vikram', 'Meera', 'Sanjay', 'Ananya',
    'Deepak', 'Lakshmi', 'Rajesh', 'Kavitha', 'Suresh',
    'Nithya', 'Mohan', 'Pooja', 'Ganesh', 'Swathi',
  ];

  static const _lastNames = [
    'Kumar', 'Sharma', 'Iyer', 'Reddy', 'Nair',
    'Patel', 'Singh', 'Murugan', 'Krishnan', 'Rao',
    'Pillai', 'Das', 'Menon', 'Sundaram', 'Bhat',
  ];

  static const _genders = ['male', 'female'];

  /// Generate realistic co-rider matches based on the user's actual route.
  ///
  /// Creates 1-3 match groups, each with 1-2 co-riders whose pickup/dropoff
  /// addresses are real locations near the user's route (via reverse geocoding).
  static Future<List<MatchResult>> generateMatches(
    LocationPoint pickup,
    LocationPoint dropoff,
  ) async {
    final tripDistanceKm = pickup.distanceTo(dropoff);
    if (tripDistanceKm < 0.5) return const [];

    // Decide how many match groups (1-3)
    final matchCount = 1 + _random.nextInt(3);
    final matches = <MatchResult>[];

    for (var m = 0; m < matchCount; m++) {
      // Decide 1-2 riders per match
      final riderCount = 1 + _random.nextInt(2);
      final riders = <MatchedRider>[];

      for (var r = 0; r < riderCount; r++) {
        final rider = await _generateRider(pickup, dropoff);
        riders.add(rider);
      }

      // Route overlap: higher for riders closer to the user's route
      final overlapPercent = 70.0 + _random.nextDouble() * 25.0;

      // Fare calculation: base on distance, split by riders + user
      final totalFare = (tripDistanceKm * 22).clamp(120.0, 900.0);
      final splitCount = riders.length + 1; // riders + user
      final farePerPerson = totalFare / splitCount;
      final savingsPercent = ((1 - 1 / splitCount) * 100);

      matches.add(MatchResult(
        id: 'match_${DateTime.now().millisecondsSinceEpoch}_$m',
        rideRequestId: 'dynamic',
        riders: riders,
        routeOverlapPercent: double.parse(overlapPercent.toStringAsFixed(1)),
        estimatedFarePerPerson: double.parse(farePerPerson.toStringAsFixed(0)),
        totalFare: double.parse(totalFare.toStringAsFixed(0)),
        savingsPercent: double.parse(savingsPercent.toStringAsFixed(1)),
        matchedAt: DateTime.now(),
      ));
    }

    // Sort by savings (best match first)
    matches.sort((a, b) => b.savingsPercent.compareTo(a.savingsPercent));
    return matches;
  }

  /// Generate a single co-rider with a nearby pickup/dropoff from the route.
  static Future<MatchedRider> _generateRider(
    LocationPoint pickup,
    LocationPoint dropoff,
  ) async {
    // Offset the rider's pickup/dropoff slightly from the user's route
    final pickupOffset = _offsetPoint(
      pickup.latitude,
      pickup.longitude,
      300 + _random.nextInt(1500).toDouble(), // 300m - 1.8km
    );
    final dropoffOffset = _offsetPoint(
      dropoff.latitude,
      dropoff.longitude,
      300 + _random.nextInt(1500).toDouble(),
    );

    // Reverse geocode to get real addresses
    String riderPickupAddr;
    String riderDropoffAddr;
    try {
      riderPickupAddr = await GeocodingService.reverseGeocode(
        pickupOffset.$1,
        pickupOffset.$2,
      );
      riderDropoffAddr = await GeocodingService.reverseGeocode(
        dropoffOffset.$1,
        dropoffOffset.$2,
      );
    } catch (_) {
      riderPickupAddr = 'Nearby pickup';
      riderDropoffAddr = 'Nearby destination';
    }

    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    final gender = _genders[_random.nextInt(2)];

    // Assign gender-appropriate names
    final name = '$firstName $lastName';
    final rating = 3.8 + _random.nextDouble() * 1.2; // 3.8 - 5.0

    return MatchedRider(
      userId: 'user_dyn_${_random.nextInt(99999)}',
      name: name,
      gender: gender,
      rating: double.parse(rating.toStringAsFixed(1)),
      pickupAddress: riderPickupAddr,
      dropoffAddress: riderDropoffAddr,
      timeDifferenceMinutes: _random.nextInt(8),
    );
  }

  /// Offset a lat/lng by roughly [distanceMeters] in a random direction.
  static (double, double) _offsetPoint(
    double lat,
    double lng,
    double distanceMeters,
  ) {
    const earthRadiusM = 6_378_137.0;
    final bearing = _random.nextDouble() * 2 * pi;
    final distRatio = distanceMeters / earthRadiusM;

    final latRad = lat * pi / 180;
    final lngRad = lng * pi / 180;

    final newLat = asin(
      sin(latRad) * cos(distRatio) +
          cos(latRad) * sin(distRatio) * cos(bearing),
    );
    final newLng = lngRad +
        atan2(
          sin(bearing) * sin(distRatio) * cos(latRad),
          cos(distRatio) - sin(latRad) * sin(newLat),
        );

    return (newLat * 180 / pi, newLng * 180 / pi);
  }
}
