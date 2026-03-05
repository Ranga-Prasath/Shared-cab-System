import 'dart:math';

import 'package:shared_cab/core/constants/app_constants.dart';

class SecurityUtils {
  SecurityUtils._();

  static final _pinRandom = Random.secure();
  static final _digitOnly = RegExp(r'^\d+$');

  static bool isValidOtpFormat(String otp) {
    return otp.length == AppConstants.otpLength && _digitOnly.hasMatch(otp);
  }

  static bool isValidPhone(String input) {
    final normalized = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?\d{10,15}$').hasMatch(normalized);
  }

  static String generateSafeArrivalPin() {
    final min = pow(10, AppConstants.safeArrivalPinLength - 1).toInt();
    final max = pow(10, AppConstants.safeArrivalPinLength).toInt();
    final value = min + _pinRandom.nextInt(max - min);
    return value.toString().padLeft(AppConstants.safeArrivalPinLength, '0');
  }
}
