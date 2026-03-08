//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_v1_auth_signup_post201_response_all_of_data.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiV1AuthSignupPost201ResponseAllOfData {
  /// Returns a new [ApiV1AuthSignupPost201ResponseAllOfData] instance.
  ApiV1AuthSignupPost201ResponseAllOfData({

    required  this.accessToken,

    required  this.refreshToken,
  });

  @JsonKey(
    
    name: r'accessToken',
    required: true,
    includeIfNull: false,
  )


  final String accessToken;



  @JsonKey(
    
    name: r'refreshToken',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApiV1AuthSignupPost201ResponseAllOfData &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken;

    @override
    int get hashCode =>
        accessToken.hashCode +
        refreshToken.hashCode;

  factory ApiV1AuthSignupPost201ResponseAllOfData.fromJson(Map<String, dynamic> json) => _$ApiV1AuthSignupPost201ResponseAllOfDataFromJson(json);

  Map<String, dynamic> toJson() => _$ApiV1AuthSignupPost201ResponseAllOfDataToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

