//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:shared_cab_api_client/src/model/ride_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_ride_status_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateRideStatusRequest {
  /// Returns a new [UpdateRideStatusRequest] instance.
  UpdateRideStatusRequest({

    required  this.status,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final RideStatus status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateRideStatusRequest &&
      other.status == status;

    @override
    int get hashCode =>
        status.hashCode;

  factory UpdateRideStatusRequest.fromJson(Map<String, dynamic> json) => _$UpdateRideStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateRideStatusRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

