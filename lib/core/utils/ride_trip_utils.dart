// SPEC: Canonical Ride And Trip Lifecycle
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WHAT IT DOES:
//   Centralizes ride publication, trip construction, and fare/rider counting
//   so every screen uses the same lifecycle rules.
//
// DATA OBJECTS:
//   RideRequest - authoritative ride state stored locally / in Firestore
//   Trip - local runtime trip view derived from a RideRequest
//
// OPERATIONS:
//   prepareRideForPublication: RideRequest + direct/shared flag -> RideRequest
//   buildDirectTripFromRide: RideRequest + rider -> Trip
//   buildSharedTripFromRide: RideRequest -> Trip
//
// EDGE CASES HANDLED:
//   • missing persisted safe-arrival PIN generates one stable value per publish
//   • duplicate rider ids collapse into one participant list
//   • route-path distance is preferred when available, with pickup/dropoff fallback
//
// ASSUMPTIONS MADE:
//   • shared-ride fare is the solo fare divided by participant count
//   • direct rides should sync as active, not discoverable pending rides
//
// DONE WHEN:
//   every trip entry point derives the same rider ids, fare, and PIN from the
//   same ride state, and lifecycle tests cover those invariants.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:shared_cab/core/constants/app_constants.dart';
import 'package:shared_cab/features/trip/utils/trip_map_math.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/utils/trip_pin_generator.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/trip_model.dart';

class RideTripUtils {
  RideTripUtils._();

  static bool shouldAutoCancelRide(RideStatus status) {
    return status == RideStatus.pending;
  }

  static bool shouldSeedDemoRecurringRides({
    required bool hasAnyRides,
    required bool hasSeededDemoData,
  }) {
    return !hasAnyRides && !hasSeededDemoData;
  }

  static String resolveRideSafeArrivalPin(RideRequest ride) {
    return ride.safeArrivalPin.isNotEmpty
        ? ride.safeArrivalPin
        : generateTripPin();
  }

  static RideRequest prepareRideForPublication(
    RideRequest ride, {
    required bool directRide,
  }) {
    return ride.copyWith(
      status: directRide ? RideStatus.active : RideStatus.pending,
      safeArrivalPin: resolveRideSafeArrivalPin(ride),
      waitForAnotherRider: false,
      readyToProceed: directRide,
    );
  }

  static List<String> canonicalRiderIds(RideRequest ride) {
    final riderIds = <String>[];

    void addRider(String id) {
      if (id.isEmpty || riderIds.contains(id)) return;
      riderIds.add(id);
    }

    addRider(ride.userId);
    for (final riderId in ride.coRiderIds) {
      addRider(riderId);
    }

    return riderIds;
  }

  static double rideDistanceKm(RideRequest ride) {
    if (ride.routePath.length < 2) {
      return TripMapMath.distanceKmBetween(
        LatLng(ride.pickup.latitude, ride.pickup.longitude),
        LatLng(ride.dropoff.latitude, ride.dropoff.longitude),
      );
    }

    return TripMapMath.routeDistanceKm(
      ride.routePath
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList(),
    );
  }

  static double estimateTotalFare(double distanceKm) {
    return (distanceKm * AppConstants.farePerKm)
        .clamp(AppConstants.minFare, AppConstants.maxFare)
        .toDouble();
  }

  static double farePerRider({
    required double totalFare,
    required int riderCount,
  }) {
    final safeRiderCount = riderCount <= 0 ? 1 : riderCount;
    return totalFare / safeRiderCount;
  }

  static Trip buildDirectTripFromRide({
    required RideRequest ride,
    required String riderId,
    DateTime? startTime,
    String? tripId,
    double? distanceKm,
  }) {
    final resolvedDistanceKm = distanceKm ?? rideDistanceKm(ride);
    final totalFare = estimateTotalFare(resolvedDistanceKm);
    return Trip(
      id: tripId ?? 'trip_${DateTime.now().millisecondsSinceEpoch}',
      matchId: 'direct_${ride.id}',
      riderIds: [riderId],
      status: TripStatus.waitingForPickup,
      startTime: startTime ?? DateTime.now(),
      isNightTrip: ride.isNightRide,
      safeArrivalPin: resolveRideSafeArrivalPin(ride),
      farePerPerson: totalFare,
      tripDistanceKm: resolvedDistanceKm,
    );
  }

  static Trip buildSharedTripFromRide({
    required RideRequest ride,
    DateTime? startTime,
    String? tripId,
    double? distanceKm,
  }) {
    final riderIds = canonicalRiderIds(ride);
    final resolvedDistanceKm = distanceKm ?? rideDistanceKm(ride);
    final totalFare = estimateTotalFare(resolvedDistanceKm);
    return Trip(
      id: tripId ?? 'trip_${DateTime.now().millisecondsSinceEpoch}',
      matchId: 'shared_${ride.id}',
      riderIds: riderIds,
      status: TripStatus.waitingForPickup,
      startTime: startTime ?? DateTime.now(),
      isNightTrip: ride.isNightRide,
      safeArrivalPin: resolveRideSafeArrivalPin(ride),
      farePerPerson: farePerRider(
        totalFare: totalFare,
        riderCount: riderIds.length,
      ),
      tripDistanceKm: resolvedDistanceKm,
    );
  }
}
