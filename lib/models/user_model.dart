// -- Shared Cab System --
// Core model: User

import 'package:flutter/foundation.dart';

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

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? gender,
    double? rating,
    int? totalTrips,
    String? profileImageUrl,
    List<EmergencyContact>? emergencyContacts,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'gender': gender,
    'rating': rating,
    'totalTrips': totalTrips,
    'profileImageUrl': profileImageUrl,
    'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
    'isVerified': isVerified,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    final contacts = json['emergencyContacts'] as List<dynamic>? ?? const [];
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      gender: json['gender'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
      profileImageUrl: json['profileImageUrl'] as String?,
      emergencyContacts: contacts
          .map(
            (item) => EmergencyContact.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, phone: $phone, gender: $gender, rating: $rating, totalTrips: $totalTrips, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.gender == gender &&
        other.rating == rating &&
        other.totalTrips == totalTrips &&
        other.profileImageUrl == profileImageUrl &&
        listEquals(other.emergencyContacts, emergencyContacts) &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    phone,
    email,
    gender,
    rating,
    totalTrips,
    profileImageUrl,
    Object.hashAll(emergencyContacts),
    isVerified,
  );
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

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String,
    );
  }

  @override
  String toString() {
    return 'EmergencyContact(id: $id, name: $name, phone: $phone, relationship: $relationship)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyContact &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.relationship == relationship;
  }

  @override
  int get hashCode => Object.hash(id, name, phone, relationship);
}
