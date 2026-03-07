// Legacy placeholder kept for compatibility with earlier map experiments.
// The current no-key demo mode uses flutter_map widget markers instead.

class TripMapIcons {
  const TripMapIcons();
}

class TripMarkerFactory {
  TripMarkerFactory._();

  static Future<TripMapIcons> create() async {
    return const TripMapIcons();
  }
}
