// SPEC: Trip PIN Generator
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WHAT IT DOES:
//   Creates a random 4-digit trip PIN each time a trip is started.
//
// DATA OBJECTS:
//   Trip PIN - 4 numeric characters used for safe arrival verification.
//   Random source - optional injected generator for deterministic tests.
//
// OPERATIONS:
//   generateTripPin: Random? -> String
//
// EDGE CASES HANDLED:
//   • Always returns exactly 4 digits, including leading zeroes.
//   • Supports injected Random for repeatable tests.
//   • Avoids hardcoded demo PIN reuse across trip creation flows.
//
// ASSUMPTIONS MADE:
//   • Demo validation only needs an in-memory PIN, not backend persistence.
//   • A numeric 4-digit PIN is sufficient for this prototype.
//
// DONE WHEN:
//   Every newly created Trip uses generateTripPin() instead of a fixed value.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:math';

String generateTripPin({Random? random}) {
  final generator = random ?? Random.secure();
  final buffer = StringBuffer();

  for (var i = 0; i < 4; i++) {
    buffer.write(generator.nextInt(10));
  }

  return buffer.toString();
}
