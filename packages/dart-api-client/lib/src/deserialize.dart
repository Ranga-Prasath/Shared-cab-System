import 'package:shared_cab_api_client/src/model/api_error.dart';
import 'package:shared_cab_api_client/src/model/api_success.dart';
import 'package:shared_cab_api_client/src/model/api_v1_auth_signup_post201_response.dart';
import 'package:shared_cab_api_client/src/model/api_v1_auth_signup_post201_response_all_of_data.dart';
import 'package:shared_cab_api_client/src/model/api_v1_rides_get200_response.dart';
import 'package:shared_cab_api_client/src/model/api_v1_rides_id_match_post200_response.dart';
import 'package:shared_cab_api_client/src/model/api_v1_rides_id_route_get200_response.dart';
import 'package:shared_cab_api_client/src/model/api_v1_rides_post201_response.dart';
import 'package:shared_cab_api_client/src/model/api_v1_users_me_get200_response.dart';
import 'package:shared_cab_api_client/src/model/create_ride_request.dart';
import 'package:shared_cab_api_client/src/model/directions_request.dart';
import 'package:shared_cab_api_client/src/model/directions_response.dart';
import 'package:shared_cab_api_client/src/model/login_request.dart';
import 'package:shared_cab_api_client/src/model/match_result.dart';
import 'package:shared_cab_api_client/src/model/match_trigger_request.dart';
import 'package:shared_cab_api_client/src/model/profile.dart';
import 'package:shared_cab_api_client/src/model/ride.dart';
import 'package:shared_cab_api_client/src/model/signup_request.dart';
import 'package:shared_cab_api_client/src/model/update_profile_request.dart';
import 'package:shared_cab_api_client/src/model/update_ride_status_request.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'ApiError':
          return ApiError.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiSuccess':
          return ApiSuccess.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiV1AuthSignupPost201Response':
          return ApiV1AuthSignupPost201Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiV1AuthSignupPost201ResponseAllOfData':
          return ApiV1AuthSignupPost201ResponseAllOfData.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiV1RidesGet200Response':
          return ApiV1RidesGet200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiV1RidesIdMatchPost200Response':
          return ApiV1RidesIdMatchPost200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiV1RidesIdRouteGet200Response':
          return ApiV1RidesIdRouteGet200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiV1RidesPost201Response':
          return ApiV1RidesPost201Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApiV1UsersMeGet200Response':
          return ApiV1UsersMeGet200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateRideRequest':
          return CreateRideRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DirectionsRequest':
          return DirectionsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DirectionsResponse':
          return DirectionsResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LoginRequest':
          return LoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MatchResult':
          return MatchResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MatchTriggerRequest':
          return MatchTriggerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Profile':
          return Profile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Ride':
          return Ride.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RideStatus':
          
          
        case 'SignupRequest':
          return SignupRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateProfileRequest':
          return UpdateProfileRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateRideStatusRequest':
          return UpdateRideStatusRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UserRole':
          
          
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }