// Firebase options for project `awaken-27f39` (Awaken).
//
// Generated from Firebase CLI sdkconfig for the Android app
// `1:230513820686:android:c71ef9ea26c0c232d0285f`. Re-run
// `firebase apps:sdkconfig` after adding iOS/Web apps.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options are not configured yet.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase options are not configured yet. Add an iOS app in '
          'Firebase Console and download GoogleService-Info.plist.',
        );
      default:
        throw UnsupportedError(
          'Firebase is only configured for Android in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZJQFYBKcCdEStfr9McOiD5bWWbC3V7A8',
    appId: '1:230513820686:android:c71ef9ea26c0c232d0285f',
    messagingSenderId: '230513820686',
    projectId: 'awaken-27f39',
    storageBucket: 'awaken-27f39.firebasestorage.app',
  );
}
