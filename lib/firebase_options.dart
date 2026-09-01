// Generated from google-services.json for project cyclecare-84454
// ignore_for_file: lines_longer_than_80_chars, type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration, per platform.
///
/// Only Android is configured. iOS and web need a `GoogleService-Info.plist` /
/// web app registered in the Firebase console, and there is no way to fabricate
/// those keys here.
///
/// [isConfigured] exists so callers can *ask* instead of catching. Previously
/// `currentPlatform` threw on iOS and `main()` relied on a try/catch to notice —
/// using an exception for an expected, known condition, which makes a real
/// initialisation failure indistinguishable from "this platform was never set
/// up". Push notifications are simply absent on unconfigured platforms; every
/// other feature is local-first and works untouched.
class DefaultFirebaseOptions {
  /// Whether this platform has real Firebase credentials compiled in.
  static bool get isConfigured {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is not configured for web. Check DefaultFirebaseOptions.isConfigured first.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase is not configured for iOS. Add GoogleService-Info.plist and '
          'the iOS options here, then check isConfigured before initialising.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not available for this platform.',
        );
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
