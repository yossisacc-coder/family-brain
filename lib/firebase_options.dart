import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default options used with the Firebase Emulator Suite.
///
/// Replace these values with a real Firebase project before shipping to
/// production (`flutterfire configure`), then run with
/// `--dart-define=USE_EMULATOR=false`.
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-family-brain',
    appId: '1:1:web:familybrain',
    messagingSenderId: '1',
    projectId: 'family-brain-dev',
    authDomain: 'family-brain-dev.firebaseapp.com',
    storageBucket: 'family-brain-dev.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-family-brain',
    appId: '1:1:android:familybrain',
    messagingSenderId: '1',
    projectId: 'family-brain-dev',
    storageBucket: 'family-brain-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-family-brain',
    appId: '1:1:ios:familybrain',
    messagingSenderId: '1',
    projectId: 'family-brain-dev',
    storageBucket: 'family-brain-dev.appspot.com',
    iosBundleId: 'com.familybrain.familyBrain',
  );
}
