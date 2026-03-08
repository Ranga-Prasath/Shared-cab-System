# shared_cab_api_client.api.RidesApi

## Load the API package
```dart
import 'package:shared_cab_api_client/api.dart';
```

All URIs are relative to *http://localhost:4000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiV1RidesGet**](RidesApi.md#apiv1ridesget) | **GET** /api/v1/rides | 
[**apiV1RidesIdGet**](RidesApi.md#apiv1ridesidget) | **GET** /api/v1/rides/{id} | 
[**apiV1RidesIdStatusPatch**](RidesApi.md#apiv1ridesidstatuspatch) | **PATCH** /api/v1/rides/{id}/status | 
[**apiV1RidesPost**](RidesApi.md#apiv1ridespost) | **POST** /api/v1/rides | 


# **apiV1RidesGet**
> ApiV1RidesGet200Response apiV1RidesGet()



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getRidesApi();

try {
    final response = api.apiV1RidesGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling RidesApi->apiV1RidesGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiV1RidesGet200Response**](ApiV1RidesGet200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiV1RidesIdGet**
> ApiV1RidesPost201Response apiV1RidesIdGet(id)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getRidesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.apiV1RidesIdGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RidesApi->apiV1RidesIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiV1RidesPost201Response**](ApiV1RidesPost201Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiV1RidesIdStatusPatch**
> ApiV1RidesPost201Response apiV1RidesIdStatusPatch(id, updateRideStatusRequest)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getRidesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final UpdateRideStatusRequest updateRideStatusRequest = ; // UpdateRideStatusRequest | 

try {
    final response = api.apiV1RidesIdStatusPatch(id, updateRideStatusRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RidesApi->apiV1RidesIdStatusPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateRideStatusRequest** | [**UpdateRideStatusRequest**](UpdateRideStatusRequest.md)|  | 

### Return type

[**ApiV1RidesPost201Response**](ApiV1RidesPost201Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiV1RidesPost**
> ApiV1RidesPost201Response apiV1RidesPost(createRideRequest)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getRidesApi();
final CreateRideRequest createRideRequest = ; // CreateRideRequest | 

try {
    final response = api.apiV1RidesPost(createRideRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RidesApi->apiV1RidesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createRideRequest** | [**CreateRideRequest**](CreateRideRequest.md)|  | 

### Return type

[**ApiV1RidesPost201Response**](ApiV1RidesPost201Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

