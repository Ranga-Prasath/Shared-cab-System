//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:shared_cab_api_client/src/model/match_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_v1_rides_id_match_post200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiV1RidesIdMatchPost200Response {
  /// Returns a new [ApiV1RidesIdMatchPost200Response] instance.
  ApiV1RidesIdMatchPost200Response({

    required  this.success,

     this.data,
  });

  @JsonKey(
    
    name: r'success',
    required: true,
    includeIfNull: false,
  )


  final ApiV1RidesIdMatchPost200ResponseSuccessEnum success;



  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false,
  )


  final List<MatchResult>? data;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApiV1RidesIdMatchPost200Response &&
      other.success == success &&
      other.data == data;

    @override
    int get hashCode =>
        success.hashCode +
        data.hashCode;

  factory ApiV1RidesIdMatchPost200Response.fromJson(Map<String, dynamic> json) => _$ApiV1RidesIdMatchPost200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiV1RidesIdMatchPost200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApiV1RidesIdMatchPost200ResponseSuccessEnum {
@JsonValue('true')
true_('true');

const ApiV1RidesIdMatchPost200ResponseSuccessEnum(this.value);

final String value;

@override
String toString() => value;
}


