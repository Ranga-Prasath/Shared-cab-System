/// -- Shared Cab System --
/// Centralized constants for demo behavior and configuration.
class AppConstants {
  AppConstants._();

  static const mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const mapUserAgent = 'com.sharedcab.app';

  static const fallbackLatitude = 13.0827;
  static const fallbackLongitude = 80.2707;

  static const farePerKm = 22.0;
  static const minFare = 120.0;
  static const maxFare = 900.0;

  static const demoOtp = '1234';
  static const otpLength = 4;
  static const maxOtpAttempts = 5;
  static const otpLockDurationSeconds = 30;

  static const safeArrivalPinLength = 4;
}
