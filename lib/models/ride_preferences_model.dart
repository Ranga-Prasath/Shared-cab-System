// -- Shared Cab System --
// Core model: Ride Preferences

class RidePreferences {
  final bool acPreferred;
  final bool musicAllowed;
  final bool petFriendly;
  final bool extraLuggage;
  final bool silentRide;
  final bool windowSeat;

  const RidePreferences({
    this.acPreferred = true,
    this.musicAllowed = true,
    this.petFriendly = false,
    this.extraLuggage = false,
    this.silentRide = false,
    this.windowSeat = false,
  });

  RidePreferences copyWith({
    bool? acPreferred,
    bool? musicAllowed,
    bool? petFriendly,
    bool? extraLuggage,
    bool? silentRide,
    bool? windowSeat,
  }) {
    return RidePreferences(
      acPreferred: acPreferred ?? this.acPreferred,
      musicAllowed: musicAllowed ?? this.musicAllowed,
      petFriendly: petFriendly ?? this.petFriendly,
      extraLuggage: extraLuggage ?? this.extraLuggage,
      silentRide: silentRide ?? this.silentRide,
      windowSeat: windowSeat ?? this.windowSeat,
    );
  }

  /// Returns a list of active preference labels for display as tags
  List<String> get activeTags {
    final tags = <String>[];
    if (acPreferred) tags.add('❄️ AC');
    if (musicAllowed) tags.add('🎵 Music');
    if (petFriendly) tags.add('🐾 Pet-Friendly');
    if (extraLuggage) tags.add('🧳 Luggage');
    if (silentRide) tags.add('🤫 Silent');
    if (windowSeat) tags.add('🪟 Window');
    return tags;
  }
}
