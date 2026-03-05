// -- Shared Cab System --
// Core model: Recurring Ride Schedule

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/models/location_model.dart';

class RecurringRide {
  final String id;
  final String userId;
  final LocationPoint pickup;
  final LocationPoint dropoff;
  final TimeOfDay departureTime;
  final List<int> activeDays; // 1=Mon, 2=Tue, ..., 7=Sun
  final bool isActive;
  final DateTime createdAt;

  const RecurringRide({
    required this.id,
    required this.userId,
    required this.pickup,
    required this.dropoff,
    required this.departureTime,
    required this.activeDays,
    this.isActive = true,
    required this.createdAt,
  });

  RecurringRide copyWith({
    String? id,
    String? userId,
    bool? isActive,
    LocationPoint? pickup,
    LocationPoint? dropoff,
    TimeOfDay? departureTime,
    List<int>? activeDays,
    DateTime? createdAt,
  }) {
    return RecurringRide(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      departureTime: departureTime ?? this.departureTime,
      activeDays: [...(activeDays ?? this.activeDays)],
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether this ride is during night hours (9 PM - 6 AM)
  bool get isNightRide {
    return isNightTimeOfDay(departureTime);
  }

  /// Human-readable day list (e.g., "Mon, Wed, Fri")
  String get daysLabel {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(activeDays)..sort();

    // Check for common patterns
    if (sorted.length == 5 && sorted.every((d) => d >= 1 && d <= 5)) {
      return 'Weekdays';
    }
    if (sorted.length == 2 && sorted[0] == 6 && sorted[1] == 7) {
      return 'Weekends';
    }
    if (sorted.length == 7) {
      return 'Every day';
    }

    return sorted.map((d) => dayNames[d - 1]).join(', ');
  }

  /// Formatted departure time string
  String get timeLabel {
    final h = departureTime.hour;
    final m = departureTime.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'departureHour': departureTime.hour,
    'departureMinute': departureTime.minute,
    'activeDays': activeDays,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecurringRide.fromJson(Map<String, dynamic> json) {
    final days = json['activeDays'] as List<dynamic>? ?? const [];
    return RecurringRide(
      id: json['id'] as String,
      userId: json['userId'] as String,
      pickup: LocationPoint.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: LocationPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
      departureTime: TimeOfDay(
        hour: (json['departureHour'] as num).toInt(),
        minute: (json['departureMinute'] as num).toInt(),
      ),
      activeDays: days.map((item) => (item as num).toInt()).toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'RecurringRide(id: $id, userId: $userId, isActive: $isActive, departure: ${departureTime.hour}:${departureTime.minute})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringRide &&
        other.id == id &&
        other.userId == userId &&
        other.pickup == pickup &&
        other.dropoff == dropoff &&
        other.departureTime == departureTime &&
        listEquals(other.activeDays, activeDays) &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    pickup,
    dropoff,
    departureTime,
    Object.hashAll(activeDays),
    isActive,
    createdAt,
  );
}
