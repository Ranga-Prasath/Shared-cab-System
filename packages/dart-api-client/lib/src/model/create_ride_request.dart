//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_ride_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateRideRequest {
  /// Returns a new [CreateRideRequest] instance.
  CreateRideRequest({

    required  this.pickupLocation,

    required  this.dropoffLocation,

    required  this.pickupAddress,

    required  this.dropoffAddress,

    required  this.scheduledAt,
  });

      /// GeoJSON order [longitude, latitude]
  @JsonKey(
    
    name: r'pickupLocation',
    required: true,
    includeIfNull: false,
  )


  final List<Object> pickupLocation;



      /// GeoJSON order [longitude, latitude]
  @JsonKey(
    
    name: r'dropoffLocation',
    required: true,
    includeIfNull: false,
  )


  final List<Object> dropoffLocation;



  @JsonKey(
    
    name: r'pickupAddress',
    required: true,
    includeIfNull: false,
  )


  final String pickupAddress;



  @JsonKey(
    
    name: r'dropoffAddress',
    required: true,
    includeIfNull: false,
  )


  final String dropoffAddress;



  @JsonKey(
    
    name: r'scheduledAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime scheduledAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateRideRequest &&
      other.pickupLocation == pickupLocation &&
      other.dropoffLocation == dropoffLocation &&
      other.pickupAddress == pickupAddress &&
      other.dropoffAddress == dropoffAddress &&
      other.scheduledAt == scheduledAt;

    @override
    int get hashCode =>
        pickupLocation.hashCode +
        dropoffLocation.hashCode +
        pickupAddress.hashCode +
        dropoffAddress.hashCode +
        scheduledAt.hashCode;

  factory CreateRideRequest.fromJson(Map<String, dynamic> json) => _$CreateRideRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRideRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

