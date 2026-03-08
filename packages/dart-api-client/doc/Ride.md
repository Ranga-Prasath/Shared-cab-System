# shared_cab_api_client.model.Ride

## Load the model package
```dart
import 'package:shared_cab_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**passengerId** | **String** |  | 
**driverId** | **String** |  | [optional] 
**status** | [**RideStatus**](RideStatus.md) |  | 
**pickupLocation** | **List&lt;Object&gt;** | GeoJSON order [longitude, latitude] | 
**dropoffLocation** | **List&lt;Object&gt;** | GeoJSON order [longitude, latitude] | 
**pickupAddress** | **String** |  | 
**dropoffAddress** | **String** |  | 
**routePolyline** | **String** |  | 
**estimatedFare** | **num** |  | 
**actualFare** | **num** |  | [optional] 
**scheduledAt** | [**DateTime**](DateTime.md) |  | [optional] 
**startedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**completedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


