import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/utils/trip_pin_generator.dart';

void main() {
  test('generateTripPin returns four numeric characters', () {
    final pin = generateTripPin(random: Random(7));

    expect(pin, hasLength(4));
    expect(RegExp(r'^\d{4}$').hasMatch(pin), isTrue);
  });
}
