// -- Shared Cab System --
// Mock data for demo

import 'package:flutter/material.dart';
import 'package:shared_cab/models/user_model.dart';
import 'package:shared_cab/models/match_model.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/route_deviation_model.dart';
import 'package:shared_cab/models/recurring_ride_model.dart';

class MockData {
  MockData._();

  // ── Mock Users ──
  static const demoUser = User(
    id: 'user_001',
    name: 'Ranga Prasath',
    phone: '+91 98765 43210',
    email: 'ranga@example.com',
    gender: 'male',
    rating: 4.8,
    totalTrips: 24,
    isVerified: true,
    emergencyContacts: [
      EmergencyContact(
        id: 'ec_001',
        name: 'Mom',
        phone: '+91 98765 11111',
        relationship: 'Mother',
      ),
      EmergencyContact(
        id: 'ec_002',
        name: 'Dad',
        phone: '+91 98765 22222',
        relationship: 'Father',
      ),
    ],
  );

  // ── Mock Locations (Chennai-based) ──
  static const locationChennaiCentral = LocationPoint(
    latitude: 13.0827,
    longitude: 80.2707,
    address: 'Chennai Central Railway Station',
    landmark: 'Central Station',
  );

  static const locationAnnanagar = LocationPoint(
    latitude: 13.0850,
    longitude: 80.2101,
    address: 'Anna Nagar, Chennai',
    landmark: 'Anna Nagar Tower',
  );

  static const locationTNagar = LocationPoint(
    latitude: 13.0418,
    longitude: 80.2341,
    address: 'T. Nagar, Chennai',
    landmark: 'Pondy Bazaar',
  );

  static const locationAdyar = LocationPoint(
    latitude: 13.0067,
    longitude: 80.2565,
    address: 'Adyar, Chennai',
    landmark: 'Adyar Signal',
  );

  static const locationOMR = LocationPoint(
    latitude: 12.9516,
    longitude: 80.2413,
    address: 'OMR, Sholinganallur',
    landmark: 'Tidel Park',
  );

  static const locationVelachery = LocationPoint(
    latitude: 12.9815,
    longitude: 80.2180,
    address: 'Velachery, Chennai',
    landmark: 'Velachery Junction',
  );

  static const availableLocations = <LocationPoint>[
    locationChennaiCentral,
    locationAnnanagar,
    locationTNagar,
    locationAdyar,
    locationOMR,
    locationVelachery,
  ];

  // ── Mock Match Results ──
  static List<MatchResult> getMockMatches(String rideId) {
    return [
      MatchResult(
        id: 'match_001',
        rideRequestId: rideId,
        riders: const [
          MatchedRider(
            userId: 'user_002',
            name: 'Priya Sharma',
            gender: 'female',
            rating: 4.9,
            pickupAddress: 'Anna Nagar Tower',
            dropoffAddress: 'OMR, Sholinganallur',
          ),
          MatchedRider(
            userId: 'user_003',
            name: 'Arun Kumar',
            gender: 'male',
            rating: 4.6,
            pickupAddress: 'Chennai Central',
            dropoffAddress: 'OMR, Sholinganallur',
          ),
        ],
        routeOverlapPercent: 87.5,
        estimatedFarePerPerson: 120.0,
        totalFare: 360.0,
        savingsPercent: 66.7,
        matchedAt: DateTime.now(),
      ),
      MatchResult(
        id: 'match_002',
        rideRequestId: rideId,
        riders: const [
          MatchedRider(
            userId: 'user_005',
            name: 'Vikram Singh',
            gender: 'male',
            rating: 4.5,
            pickupAddress: 'T. Nagar',
            dropoffAddress: 'Velachery',
          ),
        ],
        routeOverlapPercent: 82.3,
        estimatedFarePerPerson: 150.0,
        totalFare: 300.0,
        savingsPercent: 50.0,
        matchedAt: DateTime.now(),
      ),
    ];
  }

  // ── Mock Route Deviation ──
  static RouteDeviation getMockDeviation(String tripId) {
    return RouteDeviation(
      tripId: tripId,
      deviationDistanceKm: 1.2,
      expectedLocation: locationOMR,
      actualLocation: const LocationPoint(
        latitude: 12.9616,
        longitude: 80.2213,
        address: 'Unknown Road, Near Pallikaranai',
        landmark: 'Off-route area',
      ),
      detectedAt: DateTime.now(),
      severity: DeviationSeverity.high,
    );
  }

  // ── Mock Recurring Rides ──
  static List<RecurringRide> get mockRecurringRides => [
    RecurringRide(
      id: 'rec_001',
      userId: 'user_001',
      pickup: locationAnnanagar,
      dropoff: locationOMR,
      departureTime: const TimeOfDay(hour: 8, minute: 0),
      activeDays: const [1, 2, 3, 4, 5], // Mon-Fri
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    RecurringRide(
      id: 'rec_002',
      userId: 'user_001',
      pickup: locationTNagar,
      dropoff: locationAdyar,
      departureTime: const TimeOfDay(hour: 10, minute: 0),
      activeDays: const [6], // Sat
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}
