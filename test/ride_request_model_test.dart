// -- Shared Cab System --

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';

void main() {
  group('RideRequest serialization', () {
    test('round-trips accepted pickup stops and ride flags', () {
      final ride = RideRequest(
        id: 'ride-1',
        userId: 'host-1',
        userName: 'Host',
        pickup: const LocationPoint(
          latitude: 13.001,
          longitude: 80.001,
          address: 'REC',
        ),
        dropoff: const LocationPoint(
          latitude: 13.100,
          longitude: 80.200,
          address: 'Destination',
        ),
        departureTime: DateTime.fromMillisecondsSinceEpoch(1000),
        createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
        coRiderIds: const ['rider-2', 'rider-3'],
        waitForAnotherRider: true,
        readyToProceed: false,
        acceptedPickupStops: const [
          RidePickupStop(
            riderId: 'rider-2',
            riderName: 'Rider Two',
            latitude: 13.020,
            longitude: 80.020,
            address: 'Stop 2',
          ),
          RidePickupStop(
            riderId: 'rider-3',
            riderName: 'Rider Three',
            latitude: 13.030,
            longitude: 80.030,
            address: 'Stop 3',
          ),
        ],
        routePath: const [
          RideRoutePoint(latitude: 13.001, longitude: 80.001),
          RideRoutePoint(latitude: 13.020, longitude: 80.050),
          RideRoutePoint(latitude: 13.100, longitude: 80.200),
        ],
      );

      final restored = RideRequest.fromMap(ride.toMap());

      expect(restored.waitForAnotherRider, isTrue);
      expect(restored.readyToProceed, isFalse);
      expect(restored.coRiderIds, const ['rider-2', 'rider-3']);
      expect(restored.acceptedPickupStops.length, 2);
      expect(restored.acceptedPickupStops[0].riderId, 'rider-2');
      expect(restored.acceptedPickupStops[1].address, 'Stop 3');
      expect(restored.routePath.length, 3);
      expect(restored.routePath[1].longitude, 80.050);
    });
  });
}
