import 'package:test/test.dart';
import 'package:shared_cab_api_client/shared_cab_api_client.dart';


/// tests for UsersApi
void main() {
  final instance = SharedCabApiClient().getUsersApi();

  group(UsersApi, () {
    //Future<ApiV1UsersMeGet200Response> apiV1UsersMeGet() async
    test('test apiV1UsersMeGet', () async {
      // TODO
    });

    //Future<ApiV1UsersMeGet200Response> apiV1UsersMePatch(UpdateProfileRequest updateProfileRequest) async
    test('test apiV1UsersMePatch', () async {
      // TODO
    });

  });
}
