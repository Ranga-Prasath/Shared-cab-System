// -- Shared Cab System --
// Auth Service — Firebase email/password authentication + Firestore user profiles

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_cab/firebase_options.dart';
import 'package:shared_cab/models/user_model.dart';

class AuthService {
  AuthService._();

  static fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static User? _fallbackSessionUser;
  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  /// Stream of auth state changes (null = signed out)
  static Stream<fb.User?> get authStateChanges {
    if (!isFirebaseReady) {
      return Stream<fb.User?>.value(null);
    }
    return _auth.authStateChanges();
  }

  /// Currently signed-in Firebase user (synchronous check)
  static fb.User? get currentFirebaseUser =>
      isFirebaseReady ? _auth.currentUser : null;
  static String? get currentUserId =>
      currentFirebaseUser?.uid ?? _fallbackSessionUser?.id;
  static User? get currentUserProfile => _fallbackSessionUser;

  /// Sign up a new user with email + password and save profile to Firestore.
  static Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    try {
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
      _fallbackSessionUser = null;
      return user;
    } catch (error, stackTrace) {
      debugPrint('[AuthService.signUp] Firebase sign-up failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      final response = await _restEmailPasswordAuth(
        email: email,
        password: password,
        createAccount: true,
      );

      final user = User(
        id: response.localId,
        name: name.trim(),
        phone: '',
        email: email.trim(),
        gender: gender,
        rating: 5.0,
        totalTrips: 0,
        isVerified: true,
      );
      _fallbackSessionUser = user;
      return user;
    }
  }

  /// Sign in with email + password and load the user profile from Firestore.
  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      _fallbackSessionUser = null;
      return await getUserProfile(uid);
    } catch (error, stackTrace) {
      debugPrint('[AuthService.signIn] Firebase sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      final response = await _restEmailPasswordAuth(
        email: email,
        password: password,
      );

      final user = User(
        id: response.localId,
        name: _displayNameFromEmail(email),
        phone: '',
        email: response.email,
        gender: 'other',
        rating: 5.0,
        totalTrips: 0,
        isVerified: true,
      );
      _fallbackSessionUser = user;
      return user;
    }
  }

  /// Load user profile from Firestore.
  static Future<User> getUserProfile(String uid) async {
    if (isFirebaseReady) {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return User.fromMap(doc.data()!);
      }
    }

    // Fallback: create a basic profile from auth data
    final fbUser = currentFirebaseUser;
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
    _fallbackSessionUser = null;
    if (!isFirebaseReady) return;
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  static Future<_RestAuthResponse> _restEmailPasswordAuth({
    required String email,
    required String password,
    bool createAccount = false,
  }) async {
    final endpoint = createAccount
        ? 'accounts:signUp'
        : 'accounts:signInWithPassword';
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/$endpoint?key=${DefaultFirebaseOptions.web.apiKey}',
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(response.body);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _RestAuthResponse(
      localId: json['localId']?.toString() ?? '',
      email: json['email']?.toString() ?? email.trim(),
    );
  }

  static String _displayNameFromEmail(String email) {
    final localPart = email.trim().split('@').first;
    if (localPart.isEmpty) return 'User';
    return localPart;
  }
}

class _RestAuthResponse {
  final String localId;
  final String email;

  const _RestAuthResponse({required this.localId, required this.email});
}
