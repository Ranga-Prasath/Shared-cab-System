# shared_cab_api_client.api.MatchingApi

## Load the API package
```dart
import 'package:shared_cab_api_client/api.dart';
```

All URIs are relative to *http://localhost:4000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiV1MatchingAvailableGet**](MatchingApi.md#apiv1matchingavailableget) | **GET** /api/v1/matching/available | 
[**apiV1RidesIdMatchPost**](MatchingApi.md#apiv1ridesidmatchpost) | **POST** /api/v1/rides/{id}/match | 


# **apiV1MatchingAvailableGet**
> ApiV1RidesIdMatchPost200Response apiV1MatchingAvailableGet(pickupLon, pickupLat, dropoffLon, dropoffLat)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getMatchingApi();
final num pickupLon = 8.14; // num | 
final num pickupLat = 8.14; // num | 
final num dropoffLon = 8.14; // num | 
final num dropoffLat = 8.14; // num | 

try {
    final response = api.apiV1MatchingAvailableGet(pickupLon, pickupLat, dropoffLon, dropoffLat);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MatchingApi->apiV1MatchingAvailableGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pickupLon** | **num**|  | 
 **pickupLat** | **num**|  | 
 **dropoffLon** | **num**|  | 
 **dropoffLat** | **num**|  | 

### Return type

[**ApiV1RidesIdMatchPost200Response**](ApiV1RidesIdMatchPost200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiV1RidesIdMatchPost**
> ApiV1RidesIdMatchPost200Response apiV1RidesIdMatchPost(id, matchTriggerRequest)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getMatchingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final MatchTriggerRequest matchTriggerRequest = ; // MatchTriggerRequest | 

try {
    final response = api.apiV1RidesIdMatchPost(id, matchTriggerRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MatchingApi->apiV1RidesIdMatchPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **matchTriggerRequest** | [**MatchTriggerRequest**](MatchTriggerRequest.md)|  | [optional] 

### Return type

[**ApiV1RidesIdMatchPost200Response**](ApiV1RidesIdMatchPost200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

