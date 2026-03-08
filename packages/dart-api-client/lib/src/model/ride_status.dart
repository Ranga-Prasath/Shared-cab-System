//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum RideStatus {
      @JsonValue(r'REQUESTED')
      REQUESTED(r'REQUESTED'),
      @JsonValue(r'MATCHED')
      MATCHED(r'MATCHED'),
      @JsonValue(r'EN_ROUTE')
      EN_ROUTE(r'EN_ROUTE'),
      @JsonValue(r'COMPLETED')
      COMPLETED(r'COMPLETED'),
      @JsonValue(r'CANCELLED')
      CANCELLED(r'CANCELLED');

  const RideStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
