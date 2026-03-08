//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:shared_cab_api_client/src/model/ride.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_v1_rides_get200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiV1RidesGet200Response {
  /// Returns a new [ApiV1RidesGet200Response] instance.
  ApiV1RidesGet200Response({

    required  this.success,

     this.data,
  });

  @JsonKey(
    
    name: r'success',
    required: true,
    includeIfNull: false,
  )


  final ApiV1RidesGet200ResponseSuccessEnum success;



  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false,
  )


  final List<Ride>? data;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApiV1RidesGet200Response &&
      other.success == success &&
      other.data == data;

    @override
    int get hashCode =>
        success.hashCode +
        data.hashCode;

  factory ApiV1RidesGet200Response.fromJson(Map<String, dynamic> json) => _$ApiV1RidesGet200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiV1RidesGet200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApiV1RidesGet200ResponseSuccessEnum {
@JsonValue('true')
true_('true');

const ApiV1RidesGet200ResponseSuccessEnum(this.value);

final String value;

@override
String toString() => value;
}


