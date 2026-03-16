import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/utils/ride_trip_utils.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';

RideRequest _buildRide({
  RideStatus status = RideStatus.pending,
  List<String> coRiderIds = const [],
  String safeArrivalPin = '',
}) {
  return RideRequest(
    id: 'ride-1',
    userId: 'host-1',
    userName: 'Host',
    userGender: 'male',
    pickup: const LocationPoint(
      latitude: 13.0000,
      longitude: 80.0000,
      address: 'Pickup',
    ),
    dropoff: const LocationPoint(
      latitude: 13.1000,
      longitude: 80.0000,
      address: 'Dropoff',
    ),
    departureTime: DateTime.fromMillisecondsSinceEpoch(1000),
    status: status,
    createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
    coRiderIds: coRiderIds,
    safeArrivalPin: safeArrivalPin,
  );
}

void main() {
  group('RideTripUtils lifecycle helpers', () {
    test('auto-cancel only applies to pending rides', () {
      expect(RideTripUtils.shouldAutoCancelRide(RideStatus.pending), isTrue);
      expect(RideTripUtils.shouldAutoCancelRide(RideStatus.requested), isFalse);
      expect(RideTripUtils.shouldAutoCancelRide(RideStatus.matched), isFalse);
      expect(RideTripUtils.shouldAutoCancelRide(RideStatus.active), isFalse);
    });

    test(
      'prepareRideForPublication makes direct rides active and keeps a pin',
      () {
        final preparedDirectRide = RideTripUtils.prepareRideForPublication(
          _buildRide(),
          directRide: true,
        );
        final preparedSharedRide = RideTripUtils.prepareRideForPublication(
          _buildRide(safeArrivalPin: '2468'),
          directRide: false,
        );

        expect(preparedDirectRide.status, RideStatus.active);
        expect(preparedDirectRide.readyToProceed, isTrue);
        expect(
          RegExp(r'^\d{4}$').hasMatch(preparedDirectRide.safeArrivalPin),
          isTrue,
        );

        expect(preparedSharedRide.status, RideStatus.pending);
        expect(preparedSharedRide.readyToProceed, isFalse);
        expect(preparedSharedRide.safeArrivalPin, '2468');
      },
    );

    test(
      'buildSharedTripFromRide dedupes riders and splits fare by participant count',
      () {
        final ride = _buildRide(
          coRiderIds: const ['rider-2', 'rider-2', 'rider-3'],
          safeArrivalPin: '1357',
        );
        final expectedTotalFare = RideTripUtils.estimateTotalFare(
          RideTripUtils.rideDistanceKm(ride),
        );
        final trip = RideTripUtils.buildSharedTripFromRide(
          ride: ride,
          startTime: DateTime.fromMillisecondsSinceEpoch(3000),
          tripId: 'trip-1',
        );

        expect(trip.riderIds, const ['host-1', 'rider-2', 'rider-3']);
        expect(trip.participantCount, 3);
        expect(trip.safeArrivalPin, '1357');
        expect(trip.farePerPerson, closeTo(expectedTotalFare / 3, 0.01));
        expect(
          trip.estimatedSavingsPerPerson,
          closeTo(expectedTotalFare - (expectedTotalFare / 3), 0.01),
        );
      },
    );

    test('demo recurring rides seed only on the first empty state', () {
      expect(
        RideTripUtils.shouldSeedDemoRecurringRides(
          hasAnyRides: false,
          hasSeededDemoData: false,
        ),
        isTrue,
      );
      expect(
        RideTripUtils.shouldSeedDemoRecurringRides(
          hasAnyRides: false,
          hasSeededDemoData: true,
        ),
        isFalse,
      );
      expect(
        RideTripUtils.shouldSeedDemoRecurringRides(
          hasAnyRides: true,
          hasSeededDemoData: false,
        ),
        isFalse,
      );
    });

    test(
      'rideDistanceKm uses accurate fallback distance for pickup to dropoff',
      () {
        final ride = _buildRide();
        final distanceKm = RideTripUtils.rideDistanceKm(ride);

        expect(distanceKm, closeTo(11.1, 0.3));
      },
    );
  });
}
