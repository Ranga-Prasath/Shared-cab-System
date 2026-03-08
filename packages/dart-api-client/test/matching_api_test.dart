import 'package:test/test.dart';
import 'package:shared_cab_api_client/shared_cab_api_client.dart';


/// tests for MatchingApi
void main() {
  final instance = SharedCabApiClient().getMatchingApi();

  group(MatchingApi, () {
    //Future<ApiV1RidesIdMatchPost200Response> apiV1MatchingAvailableGet(num pickupLon, num pickupLat, num dropoffLon, num dropoffLat) async
    test('test apiV1MatchingAvailableGet', () async {
      // TODO
    });

    //Future<ApiV1RidesIdMatchPost200Response> apiV1RidesIdMatchPost(String id, { MatchTriggerRequest matchTriggerRequest }) async
    test('test apiV1RidesIdMatchPost', () async {
      // TODO
    });

  });
}
