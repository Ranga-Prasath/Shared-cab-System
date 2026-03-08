# shared_cab_api_client.api.RoutingApi

## Load the API package
```dart
import 'package:shared_cab_api_client/api.dart';
```

All URIs are relative to *http://localhost:4000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiV1RidesIdRouteGet**](RoutingApi.md#apiv1ridesidrouteget) | **GET** /api/v1/rides/{id}/route | 
[**apiV1RoutingDirectionsPost**](RoutingApi.md#apiv1routingdirectionspost) | **POST** /api/v1/routing/directions | 


# **apiV1RidesIdRouteGet**
> ApiV1RidesIdRouteGet200Response apiV1RidesIdRouteGet(id)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getRoutingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.apiV1RidesIdRouteGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RoutingApi->apiV1RidesIdRouteGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiV1RidesIdRouteGet200Response**](ApiV1RidesIdRouteGet200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiV1RoutingDirectionsPost**
> ApiV1RidesIdRouteGet200Response apiV1RoutingDirectionsPost(directionsRequest)



### Example
```dart
import 'package:shared_cab_api_client/api.dart';

final api = SharedCabApiClient().getRoutingApi();
final DirectionsRequest directionsRequest = ; // DirectionsRequest | 

try {
    final response = api.apiV1RoutingDirectionsPost(directionsRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RoutingApi->apiV1RoutingDirectionsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **directionsRequest** | [**DirectionsRequest**](DirectionsRequest.md)|  | 

### Return type

[**ApiV1RidesIdRouteGet200Response**](ApiV1RidesIdRouteGet200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

