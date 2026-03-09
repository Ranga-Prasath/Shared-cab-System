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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'gender': gender,
      'rating': rating,
      'totalTrips': totalTrips,
      'profileImageUrl': profileImageUrl,
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
      'isVerified': isVerified,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      gender: map['gender'] ?? 'other',
      rating: (map['rating'] ?? 5.0).toDouble(),
      totalTrips: map['totalTrips'] ?? 0,
      profileImageUrl: map['profileImageUrl'],
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)
              ?.map((c) =>
                  EmergencyContact.fromMap(c as Map<String, dynamic>))
              .toList() ??
          const [],
      isVerified: map['isVerified'] ?? false,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }
}

