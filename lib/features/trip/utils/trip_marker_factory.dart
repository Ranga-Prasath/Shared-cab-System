// -- Shared Cab System --
// Legacy marker factory placeholder.

class TripMapIcons {
  const TripMapIcons();
}

class TripMarkerFactory {
  TripMarkerFactory._();

  static Future<TripMapIcons> create() async {
    return const TripMapIcons();
  }
}
