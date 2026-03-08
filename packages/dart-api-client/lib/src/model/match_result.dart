//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'match_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MatchResult {
  /// Returns a new [MatchResult] instance.
  MatchResult({

    required  this.rideId,

    required  this.matchedRideId,

    required  this.overlapPercentage,

    required  this.detourMeters,

    required  this.status,
  });

  @JsonKey(
    
    name: r'rideId',
    required: true,
    includeIfNull: false,
  )


  final String rideId;



  @JsonKey(
    
    name: r'matchedRideId',
    required: true,
    includeIfNull: false,
  )


  final String matchedRideId;



  @JsonKey(
    
    name: r'overlapPercentage',
    required: true,
    includeIfNull: false,
  )


  final num overlapPercentage;



  @JsonKey(
    
    name: r'detourMeters',
    required: true,
    includeIfNull: false,
  )


  final int detourMeters;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final MatchResultStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MatchResult &&
      other.rideId == rideId &&
      other.matchedRideId == matchedRideId &&
      other.overlapPercentage == overlapPercentage &&
      other.detourMeters == detourMeters &&
      other.status == status;

    @override
    int get hashCode =>
        rideId.hashCode +
        matchedRideId.hashCode +
        overlapPercentage.hashCode +
        detourMeters.hashCode +
        status.hashCode;

  factory MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$MatchResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MatchResultStatusEnum {
@JsonValue(r'proposed')
proposed(r'proposed'),
@JsonValue(r'accepted')
accepted(r'accepted'),
@JsonValue(r'rejected')
rejected(r'rejected');

const MatchResultStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


