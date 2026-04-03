class AppConstants {
  AppConstants._();

  static const double farePerKm = 22.0;
  static const double minFare = 120.0;
  static const double maxFare = 900.0;

  static const double routeOverlapThresholdPercent = 35.0;
  static const double matchCorridorMeters = 1200.0;

  static const int joinRequestExpiryMinutes = 15;
  static const int maxPendingJoinRequestsPerRide = 3;
  static const int requestFlowVersion = 1;
}
