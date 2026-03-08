import 'package:test/test.dart';
import 'package:shared_cab_api_client/shared_cab_api_client.dart';


/// tests for RidesApi
void main() {
  final instance = SharedCabApiClient().getRidesApi();

  group(RidesApi, () {
    //Future<ApiV1RidesGet200Response> apiV1RidesGet() async
    test('test apiV1RidesGet', () async {
      // TODO
    });

    //Future<ApiV1RidesPost201Response> apiV1RidesIdGet(String id) async
    test('test apiV1RidesIdGet', () async {
      // TODO
    });

    //Future<ApiV1RidesPost201Response> apiV1RidesIdStatusPatch(String id, UpdateRideStatusRequest updateRideStatusRequest) async
    test('test apiV1RidesIdStatusPatch', () async {
      // TODO
    });

    //Future<ApiV1RidesPost201Response> apiV1RidesPost(CreateRideRequest createRideRequest) async
    test('test apiV1RidesPost', () async {
      // TODO
    });

  });
}
