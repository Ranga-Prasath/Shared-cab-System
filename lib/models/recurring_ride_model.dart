// -- Shared Cab System --
// Core model: Recurring Ride Schedule

import 'package:flutter/material.dart';
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
    bool? isActive,
    LocationPoint? pickup,
    LocationPoint? dropoff,
    TimeOfDay? departureTime,
    List<int>? activeDays,
  }) {
    return RecurringRide(
      id: id,
      userId: userId,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      departureTime: departureTime ?? this.departureTime,
      activeDays: activeDays ?? this.activeDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
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
}
