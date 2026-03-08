//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_success.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiSuccess {
  /// Returns a new [ApiSuccess] instance.
  ApiSuccess({

    required  this.success,

     this.data,
  });

  @JsonKey(
    
    name: r'success',
    required: true,
    includeIfNull: false,
  )


  final ApiSuccessSuccessEnum success;



  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object>? data;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApiSuccess &&
      other.success == success &&
      other.data == data;

    @override
    int get hashCode =>
        success.hashCode +
        data.hashCode;

  factory ApiSuccess.fromJson(Map<String, dynamic> json) => _$ApiSuccessFromJson(json);

  Map<String, dynamic> toJson() => _$ApiSuccessToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApiSuccessSuccessEnum {
@JsonValue('true')
true_('true');

const ApiSuccessSuccessEnum(this.value);

final String value;

@override
String toString() => value;
}


