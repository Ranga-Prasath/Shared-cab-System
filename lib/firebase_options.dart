// -- Shared Cab System --
// Firebase Options — PLACEHOLDER
// Run `flutterfire configure` to replace this file with your project's config.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace these placeholder values by running:
  //   dart pub global run flutterfire_cli:flutterfire configure
  //
  // Or paste your values from Firebase Console → Project Settings → Your apps

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJE-IP3E3W0g0cAyeEeGaYPfXEegdHrP4',
    appId: '1:974731290007:web:8ca7503d22dfeab4c1d0d2',
    messagingSenderId: '974731290007',
    projectId: 'shared-cab-2',
    authDomain: 'shared-cab-2.firebaseapp.com',
    storageBucket: 'shared-cab-2.firebasestorage.app',
    measurementId: 'G-PXV0XEW9Z0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiBJp4xpWfZkGTA2VJepcOuuIUSqkhIWM',
    appId: '1:974731290007:android:131d95aed4c71344c1d0d2',
    messagingSenderId: '974731290007',
    projectId: 'shared-cab-2',
    storageBucket: 'shared-cab-2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.sharedCab',
  );
}