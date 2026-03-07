// -- Shared Cab System --
// Core model: User

class User {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String gender;
  final double rating;
  final int totalTrips;
  final String? profileImageUrl;
  final List<EmergencyContact> emergencyContacts;
  final bool isVerified;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.gender,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.profileImageUrl,
    this.emergencyContacts = const [],
    this.isVerified = false,
  });
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });
}
