//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:shared_cab_api_client/src/model/ride_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ride.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Ride {
  /// Returns a new [Ride] instance.
  Ride({

    required  this.id,

    required  this.passengerId,

     this.driverId,

    required  this.status,

    required  this.pickupLocation,

    required  this.dropoffLocation,

    required  this.pickupAddress,

    required  this.dropoffAddress,

    required  this.routePolyline,

    required  this.estimatedFare,

     this.actualFare,

     this.scheduledAt,

     this.startedAt,

     this.completedAt,

    required  this.createdAt,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'passengerId',
    required: true,
    includeIfNull: false,
  )


  final String passengerId;



  @JsonKey(
    
    name: r'driverId',
    required: false,
    includeIfNull: false,
  )


  final String? driverId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final RideStatus status;



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
    
    name: r'routePolyline',
    required: true,
    includeIfNull: false,
  )


  final String routePolyline;



  @JsonKey(
    
    name: r'estimatedFare',
    required: true,
    includeIfNull: false,
  )


  final num estimatedFare;



  @JsonKey(
    
    name: r'actualFare',
    required: false,
    includeIfNull: false,
  )


  final num? actualFare;



  @JsonKey(
    
    name: r'scheduledAt',
    required: false,
    includeIfNull: false,
  )


  final DateTime? scheduledAt;



  @JsonKey(
    
    name: r'startedAt',
    required: false,
    includeIfNull: false,
  )


  final DateTime? startedAt;



  @JsonKey(
    
    name: r'completedAt',
    required: false,
    includeIfNull: false,
  )


  final DateTime? completedAt;



  @JsonKey(
    
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Ride &&
      other.id == id &&
      other.passengerId == passengerId &&
      other.driverId == driverId &&
      other.status == status &&
      other.pickupLocation == pickupLocation &&
      other.dropoffLocation == dropoffLocation &&
      other.pickupAddress == pickupAddress &&
      other.dropoffAddress == dropoffAddress &&
      other.routePolyline == routePolyline &&
      other.estimatedFare == estimatedFare &&
      other.actualFare == actualFare &&
      other.scheduledAt == scheduledAt &&
      other.startedAt == startedAt &&
      other.completedAt == completedAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        passengerId.hashCode +
        driverId.hashCode +
        status.hashCode +
        pickupLocation.hashCode +
        dropoffLocation.hashCode +
        pickupAddress.hashCode +
        dropoffAddress.hashCode +
        routePolyline.hashCode +
        estimatedFare.hashCode +
        actualFare.hashCode +
        scheduledAt.hashCode +
        startedAt.hashCode +
        completedAt.hashCode +
        createdAt.hashCode +
        updatedAt.hashCode;

  factory Ride.fromJson(Map<String, dynamic> json) => _$RideFromJson(json);

  Map<String, dynamic> toJson() => _$RideToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

