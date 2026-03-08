//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'match_trigger_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MatchTriggerRequest {
  /// Returns a new [MatchTriggerRequest] instance.
  MatchTriggerRequest({

     this.minOverlapPercentage = 0.4,
  });

          // minimum: 0
          // maximum: 1
  @JsonKey(
    defaultValue: 0.4,
    name: r'minOverlapPercentage',
    required: false,
    includeIfNull: false,
  )


  final num? minOverlapPercentage;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MatchTriggerRequest &&
      other.minOverlapPercentage == minOverlapPercentage;

    @override
    int get hashCode =>
        minOverlapPercentage.hashCode;

  factory MatchTriggerRequest.fromJson(Map<String, dynamic> json) => _$MatchTriggerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MatchTriggerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

