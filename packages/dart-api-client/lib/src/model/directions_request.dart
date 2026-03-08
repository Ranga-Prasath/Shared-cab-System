//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'directions_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DirectionsRequest {
  /// Returns a new [DirectionsRequest] instance.
  DirectionsRequest({

    required  this.start,

    required  this.end,
  });

      /// GeoJSON order [longitude, latitude]
  @JsonKey(
    
    name: r'start',
    required: true,
    includeIfNull: false,
  )


  final List<Object> start;



      /// GeoJSON order [longitude, latitude]
  @JsonKey(
    
    name: r'end',
    required: true,
    includeIfNull: false,
  )


  final List<Object> end;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DirectionsRequest &&
      other.start == start &&
      other.end == end;

    @override
    int get hashCode =>
        start.hashCode +
        end.hashCode;

  factory DirectionsRequest.fromJson(Map<String, dynamic> json) => _$DirectionsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DirectionsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

