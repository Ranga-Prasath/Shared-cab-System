// -- Shared Cab System --
// QA screen for validating trip routing without backend dependencies

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

import 'trip_status_screen.dart';
import 'utils/trip_route_builder.dart';

class TripDebugScreen extends StatelessWidget {
  final int riders;

  const TripDebugScreen({super.key, required this.riders});

  @override
  Widget build(BuildContext context) {
    final safeRiderCount = riders.clamp(2, 3);
    final rideRequest = _buildRideRequest(safeRiderCount);
    final pickupOrderLabel = _buildPickupOrderLabel(rideRequest);
    final trip = Trip(
      id: 'qa_trip_$safeRiderCount',
      matchId: 'qa_trip_$safeRiderCount',
      riderIds: [MockData.demoUser.id, ...rideRequest.coRiderIds],
      status: TripStatus.waitingForPickup,
      startTime: DateTime.now(),
      tripDistanceKm: rideRequest.pickup.distanceTo(rideRequest.dropoff),
      farePerPerson: 180,
    );

    return ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWith((ref) => true),
        currentUserProvider.overrideWith((ref) => MockData.demoUser),
        currentRideRequestProvider.overrideWith((ref) => rideRequest),
        activeTripProvider.overrideWith((ref) => trip),
        nightModeOverrideProvider.overrideWith((ref) => false),
      ],
      child: Stack(
        children: [
          TripStatusScreen(tripId: trip.id),
          Positioned(
            top: 84,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'QA pickup order: $pickupOrderLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  RideRequest _buildRideRequest(int riderCount) {
    final acceptedStops = <RidePickupStop>[
      const RidePickupStop(
        riderId: 'qa_rider_2',
        riderName: 'Rider 2',
        latitude: 13.0469,
        longitude: 80.1117,
        address: 'Queens Land Bus Stop',
      ),
      if (riderCount == 3)
        const RidePickupStop(
          riderId: 'qa_rider_3',
          riderName: 'Rider 3',
          latitude: 13.0386,
          longitude: 80.0766,
          address: 'Rajalakshmi Engineering College',
        ),
    ];

    return RideRequest(
      id: 'qa_ride_$riderCount',
      userId: MockData.demoUser.id,
      userName: MockData.demoUser.name,
      userGender: MockData.demoUser.gender,
      pickup: const LocationPoint(
        latitude: 13.0755,
        longitude: 80.1558,
        address: 'Porur Junction',
      ),
      dropoff: const LocationPoint(
        latitude: 13.0369,
        longitude: 80.2676,
        address: 'Phoenix Marketcity',
      ),
      departureTime: DateTime.now().add(const Duration(minutes: 10)),
      status: RideStatus.matched,
      createdAt: DateTime.now(),
      coRiderIds: acceptedStops
          .map((pickupStop) => pickupStop.riderId)
          .toList(),
      readyToProceed: true,
      acceptedPickupStops: acceptedStops,
    );
  }

  String _buildPickupOrderLabel(RideRequest rideRequest) {
    final addressByKey = <String, String>{
      _pointKey(
        LatLng(rideRequest.pickup.latitude, rideRequest.pickup.longitude),
      ): rideRequest.pickup.address,
      for (final stop in rideRequest.acceptedPickupStops)
        _pointKey(LatLng(stop.latitude, stop.longitude)): stop.address,
    };

    final orderedPickups = TripRouteBuilder.orderPickupWaypoints(
      hostPickup: LatLng(
        rideRequest.pickup.latitude,
        rideRequest.pickup.longitude,
      ),
      coRiderPickups: [
        for (final stop in rideRequest.acceptedPickupStops)
          LatLng(stop.latitude, stop.longitude),
      ],
      destination: LatLng(
        rideRequest.dropoff.latitude,
        rideRequest.dropoff.longitude,
      ),
    );

    return orderedPickups
        .map((point) => addressByKey[_pointKey(point)] ?? 'Unknown pickup')
        .join(' -> ');
  }

  String _pointKey(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}|${point.longitude.toStringAsFixed(5)}';
  }
}
