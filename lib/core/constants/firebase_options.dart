// Generated from Firebase MCP / CLI SDK configs for project awaken-27f39.
// Android: android/app/google-services.json
// iOS: ios/Runner/GoogleService-Info.plist
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZJQFYBKcCdEStfr9McOiD5bWWbC3V7A8',
    appId: '1:230513820686:android:c71ef9ea26c0c232d0285f',
    messagingSenderId: '230513820686',
    projectId: 'awaken-27f39',
    storageBucket: 'awaken-27f39.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBd0CwKQXxaJpvEoukfG2zODHGi6XR_79o',
    appId: '1:230513820686:ios:084195da84579419d0285f',
    messagingSenderId: '230513820686',
    projectId: 'awaken-27f39',
    storageBucket: 'awaken-27f39.firebasestorage.app',
    iosBundleId: 'com.example.awaken',
  );
}
