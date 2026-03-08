//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:shared_cab_api_client/src/model/api_v1_auth_signup_post201_response_all_of_data.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_v1_auth_signup_post201_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiV1AuthSignupPost201Response {
  /// Returns a new [ApiV1AuthSignupPost201Response] instance.
  ApiV1AuthSignupPost201Response({

    required  this.success,

     this.data,
  });

  @JsonKey(
    
    name: r'success',
    required: true,
    includeIfNull: false,
  )


  final ApiV1AuthSignupPost201ResponseSuccessEnum success;



  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false,
  )


  final ApiV1AuthSignupPost201ResponseAllOfData? data;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApiV1AuthSignupPost201Response &&
      other.success == success &&
      other.data == data;

    @override
    int get hashCode =>
        success.hashCode +
        data.hashCode;

  factory ApiV1AuthSignupPost201Response.fromJson(Map<String, dynamic> json) => _$ApiV1AuthSignupPost201ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiV1AuthSignupPost201ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApiV1AuthSignupPost201ResponseSuccessEnum {
@JsonValue('true')
true_('true');

const ApiV1AuthSignupPost201ResponseSuccessEnum(this.value);

final String value;

@override
String toString() => value;
}


