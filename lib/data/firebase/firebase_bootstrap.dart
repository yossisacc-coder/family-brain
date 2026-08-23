import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../firebase_options.dart';

class FirebaseBootstrap {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (AppConfig.useEmulator) {
      final host = _emulatorHost();
      FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
      await FirebaseAuth.instance.useAuthEmulator(
        host,
        AppConfig.authEmulatorPort,
      );
      FirebaseFirestore.instance.useFirestoreEmulator(
        host,
        AppConfig.firestoreEmulatorPort,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
  }

  static String _emulatorHost() {
    if (kIsWeb) return AppConfig.emulatorHost;
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (AppConfig.emulatorHost == '127.0.0.1' ||
          AppConfig.emulatorHost == 'localhost') {
        return '10.0.2.2';
      }
    }
    return AppConfig.emulatorHost;
  }
}
