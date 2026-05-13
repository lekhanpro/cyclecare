// Generated from google-services.json for project cyclecare-84454
// ignore_for_file: lines_longer_than_80_chars, type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured yet');
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0HppDmrG9pEMqP9B2XW4tlR8PIF-XXCI',
    appId: '1:223534397392:android:654066887d14767de1ebd5',
    messagingSenderId: '223534397392',
    projectId: 'cyclecare-84454',
    storageBucket: 'cyclecare-84454.firebasestorage.app',
  );
}
