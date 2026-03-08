import 'package:test/test.dart';
import 'package:shared_cab_api_client/shared_cab_api_client.dart';


/// tests for AuthApi
void main() {
  final instance = SharedCabApiClient().getAuthApi();

  group(AuthApi, () {
    //Future<ApiV1AuthSignupPost201Response> apiV1AuthLoginPost(LoginRequest loginRequest) async
    test('test apiV1AuthLoginPost', () async {
      // TODO
    });

    //Future<ApiV1AuthSignupPost201Response> apiV1AuthSignupPost(SignupRequest signupRequest) async
    test('test apiV1AuthSignupPost', () async {
      // TODO
    });

  });
}
