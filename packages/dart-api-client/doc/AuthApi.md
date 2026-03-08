# shared_cab_api_client.api.AuthApi

## Load the API package
```dart
import 'package:shared_cab_api_client/api.dart';
```

All URIs are relative to *http://localhost:4000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiV1AuthLoginPost**](AuthApi.md#apiv1authloginpost) | **POST** /api/v1/auth/login | 
[**apiV1AuthSignupPost**](AuthApi.md#apiv1authsignuppost) | **POST** /api/v1/auth/signup | 


# **apiV1AuthLoginPost**
> ApiV1AuthSignupPost201Response apiV1AuthLoginPost(loginRequest)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getAuthApi();
final LoginRequest loginRequest = ; // LoginRequest | 

try {
    final response = api.apiV1AuthLoginPost(loginRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->apiV1AuthLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**ApiV1AuthSignupPost201Response**](ApiV1AuthSignupPost201Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiV1AuthSignupPost**
> ApiV1AuthSignupPost201Response apiV1AuthSignupPost(signupRequest)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getAuthApi();
final SignupRequest signupRequest = ; // SignupRequest | 

try {
    final response = api.apiV1AuthSignupPost(signupRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->apiV1AuthSignupPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **signupRequest** | [**SignupRequest**](SignupRequest.md)|  | 

### Return type

[**ApiV1AuthSignupPost201Response**](ApiV1AuthSignupPost201Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

