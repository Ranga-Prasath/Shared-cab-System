//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:shared_cab_api_client/src/model/profile.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_v1_users_me_get200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiV1UsersMeGet200Response {
  /// Returns a new [ApiV1UsersMeGet200Response] instance.
  ApiV1UsersMeGet200Response({

    required  this.success,

     this.data,
  });

  @JsonKey(
    
    name: r'success',
    required: true,
    includeIfNull: false,
  )


  final ApiV1UsersMeGet200ResponseSuccessEnum success;



  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false,
  )


  final Profile? data;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApiV1UsersMeGet200Response &&
      other.success == success &&
      other.data == data;

    @override
    int get hashCode =>
        success.hashCode +
        data.hashCode;

  factory ApiV1UsersMeGet200Response.fromJson(Map<String, dynamic> json) => _$ApiV1UsersMeGet200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiV1UsersMeGet200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApiV1UsersMeGet200ResponseSuccessEnum {
@JsonValue('true')
true_('true');

const ApiV1UsersMeGet200ResponseSuccessEnum(this.value);

final String value;

@override
String toString() => value;
}


