# shared_cab_api_client.api.UsersApi

## Load the API package
```dart
import 'package:shared_cab_api_client/api.dart';
```

All URIs are relative to *http://localhost:4000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiV1UsersMeGet**](UsersApi.md#apiv1usersmeget) | **GET** /api/v1/users/me | 
[**apiV1UsersMePatch**](UsersApi.md#apiv1usersmepatch) | **PATCH** /api/v1/users/me | 


# **apiV1UsersMeGet**
> ApiV1UsersMeGet200Response apiV1UsersMeGet()



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getUsersApi();

try {
    final response = api.apiV1UsersMeGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->apiV1UsersMeGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiV1UsersMeGet200Response**](ApiV1UsersMeGet200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiV1UsersMePatch**
> ApiV1UsersMeGet200Response apiV1UsersMePatch(updateProfileRequest)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getUsersApi();
final UpdateProfileRequest updateProfileRequest = ; // UpdateProfileRequest | 

try {
    final response = api.apiV1UsersMePatch(updateProfileRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->apiV1UsersMePatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateProfileRequest** | [**UpdateProfileRequest**](UpdateProfileRequest.md)|  | 

### Return type

[**ApiV1UsersMeGet200Response**](ApiV1UsersMeGet200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

