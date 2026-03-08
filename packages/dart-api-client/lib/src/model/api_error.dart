//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiError {
  /// Returns a new [ApiError] instance.
  ApiError({

    required  this.success,

    required  this.error,
  });

  @JsonKey(
    
    name: r'success',
    required: true,
    includeIfNull: false,
  )


  final ApiErrorSuccessEnum success;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: false,
  )


  final String error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApiError &&
      other.success == success &&
      other.error == error;

    @override
    int get hashCode =>
        success.hashCode +
        error.hashCode;

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApiErrorSuccessEnum {
@JsonValue('false')
false_('false');

const ApiErrorSuccessEnum(this.value);

final String value;

@override
String toString() => value;
}


