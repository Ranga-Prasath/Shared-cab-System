import 'package:flutter/material.dart';

bool isNightHour(int hour) => hour >= 21 || hour < 6;

bool isNightDateTime(DateTime dateTime) => isNightHour(dateTime.hour);

bool isNightTimeOfDay(TimeOfDay timeOfDay) => isNightHour(timeOfDay.hour);
