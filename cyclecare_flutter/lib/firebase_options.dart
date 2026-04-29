import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
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
    apiKey: 'AIzaSyB0HppDmrG9pEMqP9B2XW4tlR8PIF-XXCI',
    appId: '1:223534397392:android:654066887d14767de1ebd5',
    messagingSenderId: '223534397392',
    projectId: 'cyclecare-84454',
    storageBucket: 'cyclecare-84454.firebasestorage.app',
    iosBundleId: 'com.cyclecare.flutter',
  );
}
