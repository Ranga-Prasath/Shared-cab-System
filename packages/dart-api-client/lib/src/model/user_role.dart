//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum UserRole {
      @JsonValue(r'passenger')
      passenger(r'passenger'),
      @JsonValue(r'driver')
      driver(r'driver'),
      @JsonValue(r'admin')
      admin(r'admin');

  const UserRole(this.value);

  final String value;

  @override
  String toString() => value;
}
