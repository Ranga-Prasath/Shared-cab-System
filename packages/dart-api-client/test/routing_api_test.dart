import 'package:test/test.dart';
import 'package:shared_cab_api_client/shared_cab_api_client.dart';


/// tests for RoutingApi
void main() {
  final instance = SharedCabApiClient().getRoutingApi();

  group(RoutingApi, () {
    //Future<ApiV1RidesIdRouteGet200Response> apiV1RidesIdRouteGet(String id) async
    test('test apiV1RidesIdRouteGet', () async {
      // TODO
    });

    //Future<ApiV1RidesIdRouteGet200Response> apiV1RoutingDirectionsPost(DirectionsRequest directionsRequest) async
    test('test apiV1RoutingDirectionsPost', () async {
      // TODO
    });

  });
}
