//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'directions_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DirectionsResponse {
  /// Returns a new [DirectionsResponse] instance.
  DirectionsResponse({

    required  this.distanceMeters,

    required  this.durationSeconds,

    required  this.polyline,
  });

  @JsonKey(
    
    name: r'distanceMeters',
    required: true,
    includeIfNull: false,
  )


  final num distanceMeters;



  @JsonKey(
    
    name: r'durationSeconds',
    required: true,
    includeIfNull: false,
  )


  final num durationSeconds;



  @JsonKey(
    
    name: r'polyline',
    required: true,
    includeIfNull: false,
  )


  final String polyline;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DirectionsResponse &&
      other.distanceMeters == distanceMeters &&
      other.durationSeconds == durationSeconds &&
      other.polyline == polyline;

    @override
    int get hashCode =>
        distanceMeters.hashCode +
        durationSeconds.hashCode +
        polyline.hashCode;

  factory DirectionsResponse.fromJson(Map<String, dynamic> json) => _$DirectionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DirectionsResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

