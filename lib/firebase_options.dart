import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase options for the **emulator / local development** path.
///
/// These values are intentionally fake (`demo-family-brain`). They work with
/// the Firebase Emulator Suite. They are **not** a production project.
///
/// Before a store build:
/// 1. Create a real Firebase project in the Firebase Console (manual).
/// 2. Run `flutterfire configure` and replace this file.
/// 3. Add `android/app/google-services.json` from that project (do not invent
///    IDs, API keys, or SHA fingerprints).
/// 4. Keep secrets out of git.
///
/// [isPlaceholder] stays true until this file is replaced. Production bootstrap
/// refuses to start while it is true (no silent fallback to local demo).
class DefaultFirebaseOptions {
  /// True while this file still contains the committed emulator placeholders.
  static bool get isPlaceholder {
    return android.apiKey == 'demo-family-brain' ||
        android.appId == '1:1:android:familybrain' ||
        android.projectId == 'family-brain-dev';
  }

  static bool get hasRealConfiguration => !isPlaceholder;

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
