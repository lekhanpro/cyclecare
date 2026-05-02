import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0HppDmrG9pEMqP9B2XW4tlR8PIF-XXCI',
    appId: '1:223534397392:android:654066887d14767de1ebd5',
    messagingSenderId: '223534397392',
    projectId: 'cyclecare-84454',
    storageBucket: 'cyclecare-84454.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'AIzaSyB0HppDmrG9pEMqP9B2XW4tlR8PIF-XXCI',
    ),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: '223534397392',
    projectId: 'cyclecare-84454',
    storageBucket: 'cyclecare-84454.firebasestorage.app',
    iosBundleId: 'com.cyclecare.flutter',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSyB0HppDmrG9pEMqP9B2XW4tlR8PIF-XXCI',
    ),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: '223534397392',
    projectId: 'cyclecare-84454',
    authDomain: String.fromEnvironment(
      'FIREBASE_WEB_AUTH_DOMAIN',
      defaultValue: 'cyclecare-84454.firebaseapp.com',
    ),
    storageBucket: 'cyclecare-84454.firebasestorage.app',
  );
}
