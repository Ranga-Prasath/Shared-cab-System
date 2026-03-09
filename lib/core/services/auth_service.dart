// -- Shared Cab System --
// Auth Service — Firebase email/password authentication + Firestore user profiles

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_cab/models/user_model.dart';

class AuthService {
  AuthService._();

  static final _auth = fb.FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Stream of auth state changes (null = signed out)
  static Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user (synchronous check)
  static fb.User? get currentFirebaseUser => _auth.currentUser;

  /// Sign up a new user with email + password and save profile to Firestore.
  static Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    // 1. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    // 2. Build user profile
    final user = User(
      id: uid,
      name: name.trim(),
      phone: '',
      email: email.trim(),
      gender: gender,
      rating: 5.0,
      totalTrips: 0,
      isVerified: true,
    );

    // 3. Save to Firestore
    await _firestore.collection('users').doc(uid).set(user.toMap());

    return user;
  }

  /// Sign in with email + password and load the user profile from Firestore.
  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    return await getUserProfile(uid);
  }

  /// Load user profile from Firestore.
  static Future<User> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return User.fromMap(doc.data()!);
    }

    // Fallback: create a basic profile from auth data
    final fbUser = _auth.currentUser;
    return User(
      id: uid,
      name: fbUser?.displayName ?? 'User',
      phone: '',
      email: fbUser?.email ?? '',
      gender: 'other',
    );
  }

  /// Sign out.
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
