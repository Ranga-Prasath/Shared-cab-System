// -- Shared Cab System --

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/features/trip/utils/trip_route_builder.dart';

void main() {
  group('TripRouteBuilder.orderPickupWaypoints', () {
    test('starts from the pickup farthest from the destination', () {
      const hostPickup = LatLng(13.0755, 80.1558); // Porur Junction
      const fartherPickup = LatLng(13.0469, 80.1117); // Queens Land
      const destination = LatLng(13.0369, 80.2676); // Phoenix Marketcity

      final ordered = TripRouteBuilder.orderPickupWaypoints(
        hostPickup: hostPickup,
        coRiderPickups: const [fartherPickup],
        destination: destination,
      );

      expect(ordered, const [fartherPickup, hostPickup]);
    });

    test('orders three pickups from outermost corridor inward', () {
      const hostPickup = LatLng(13.0755, 80.1558); // Porur Junction
      const middlePickup = LatLng(13.0469, 80.1117); // Queens Land
      const farthestPickup = LatLng(13.0386, 80.0766); // REC
      const destination = LatLng(13.0369, 80.2676); // Phoenix Marketcity

      final ordered = TripRouteBuilder.orderPickupWaypoints(
        hostPickup: hostPickup,
        coRiderPickups: const [middlePickup, farthestPickup],
        destination: destination,
      );

      expect(ordered, const [farthestPickup, middlePickup, hostPickup]);
    });

    test('drops duplicate pickup coordinates before sorting', () {
      const hostPickup = LatLng(13.0755, 80.1558);
      const duplicatePickupA = LatLng(13.0469, 80.1117);
      const duplicatePickupB = LatLng(13.0469, 80.1117);
      const destination = LatLng(13.0369, 80.2676);

      final ordered = TripRouteBuilder.orderPickupWaypoints(
        hostPickup: hostPickup,
        coRiderPickups: const [duplicatePickupA, duplicatePickupB],
        destination: destination,
      );

      expect(ordered, const [duplicatePickupA, hostPickup]);
    });

    test('keeps input order when pickups are equally distant', () {
      const hostPickup = LatLng(13.1000, 80.2000);
      const equalPickupA = LatLng(13.2000, 80.1000);
      const equalPickupB = LatLng(13.0000, 80.1000);
      const destination = LatLng(13.1000, 80.1000);

      final ordered = TripRouteBuilder.orderPickupWaypoints(
        hostPickup: hostPickup,
        coRiderPickups: const [equalPickupA, equalPickupB],
        destination: destination,
      );

      expect(ordered, const [equalPickupA, equalPickupB, hostPickup]);
    });
  });

  group('TripRouteBuilder.routeOverlapPercent', () {
    test('detects strong overlap when two routes share the same corridor', () {
      final routeA = const [
        LatLng(13.0386, 80.0766),
        LatLng(13.0600, 80.1200),
        LatLng(13.0800, 80.1800),
        LatLng(12.9249, 80.1000),
      ];
      final routeB = const [
        LatLng(13.0475, 80.0940),
        LatLng(13.0600, 80.1200),
        LatLng(13.0800, 80.1800),
        LatLng(12.9249, 80.1000),
      ];

      final overlap = TripRouteBuilder.routeOverlapPercent(routeA, routeB);

      expect(overlap, greaterThanOrEqualTo(35));
      expect(TripRouteBuilder.routesShareCorridor(routeA, routeB), isTrue);
    });

    test('rejects routes on separate corridors', () {
      final routeA = const [
        LatLng(13.0386, 80.0766),
        LatLng(13.0600, 80.1200),
        LatLng(12.9249, 80.1000),
      ];
      final routeB = const [
        LatLng(13.2200, 80.3200),
        LatLng(13.2600, 80.3600),
        LatLng(13.3000, 80.4100),
      ];

      final overlap = TripRouteBuilder.routeOverlapPercent(routeA, routeB);

      expect(overlap, lessThan(10));
      expect(TripRouteBuilder.routesShareCorridor(routeA, routeB), isFalse);
    });
  });
}
