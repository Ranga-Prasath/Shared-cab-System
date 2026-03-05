/// -- Shared Cab System --
/// Route paths and route names.
class AppRoutes {
  AppRoutes._();

  static const loginPath = '/login';
  static const otpPath = '/otp';
  static const homePath = '/home';
  static const profilePath = '/profile';
  static const createRidePath = '/create-ride';
  static const matchesPath = '/matches/:rideId';
  static const tripStatusPath = '/trip/:tripId';
  static const tripCompletePath = '/trip-complete/:tripId';
  static const panicPath = '/panic';
  static const safeArrivalPath = '/safe-arrival/:tripId';
  static const emergencyContactsPath = '/emergency-contacts';
  static const ratingPath = '/rating/:tripId';
  static const recurringRidesPath = '/recurring-rides';
  static const createRecurringRidePath = '/create-recurring-ride';
  static const rideHistoryPath = '/ride-history';
  static const liveTrackingPath = '/live-tracking/:tripId';

  static const loginName = 'login';
  static const otpName = 'otp';
  static const homeName = 'home';
  static const profileName = 'profile';
  static const createRideName = 'createRide';
  static const matchesName = 'matches';
  static const tripStatusName = 'tripStatus';
  static const tripCompleteName = 'tripComplete';
  static const panicName = 'panic';
  static const safeArrivalName = 'safeArrival';
  static const emergencyContactsName = 'emergencyContacts';
  static const ratingName = 'rating';
  static const recurringRidesName = 'recurringRides';
  static const createRecurringRideName = 'createRecurringRide';
  static const rideHistoryName = 'rideHistory';
  static const liveTrackingName = 'liveTracking';

  static const rideIdParam = 'rideId';
  static const tripIdParam = 'tripId';
}
