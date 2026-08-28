import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'production_config_exception.dart';

/// Compile-time configuration for Family Brain.
///
/// Development (debug/profile, or an explicit local demo build):
///   `flutter run`
///   `flutter run --dart-define=BACKEND_MODE=localDemo`
///
/// Firebase against emulators (development only):
///   `flutter run --dart-define=BACKEND_MODE=firebase --dart-define=USE_EMULATOR=true`
///
/// Production / Play store builds:
///   `flutter build appbundle --dart-define-from-file=tool/production.defines.json`
///
/// Release builds default to Firebase with the emulator **off**. They do **not**
/// fall back to `localDemo` if Firebase is missing — they throw
/// [ProductionConfigException] instead.
///
/// Do not put API keys, passwords, or keystore secrets in this file.
enum BackendMode { localDemo, firebase }

class AppConfig {
  static const String appName = 'Family Brain';
  static const String version = '1.1.0';

  /// Family is the first workspace type on a platform that can grow later.
  static const String defaultWorkspaceType = 'family';

  static const String backendModeName = String.fromEnvironment(
    'BACKEND_MODE',
    defaultValue: '',
  );

  static const String useEmulatorRaw = String.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: '',
  );

  /// Public HTTPS origin of the AI gateway (no secrets).
  /// Override with `--dart-define=AI_BACKEND_URL=` (empty keeps on-device only).
  static const String aiBackendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: 'https://family-brain-ai.onrender.com',
  );

  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8088;

  /// Demo identities used **only** when [useLocalDemo] is true.
  static const String demoPhone = '+16505551234';
  static const String demoOtp = '123456';
  static const String demoName = 'Alex';
  static const String demoPartnerName = 'Maya';
  static const String demoFamilyName = 'The Cohens';
  static const String demoUserId = 'demo-user-alex';
  static const String demoPartnerId = 'demo-user-maya';
  static const String demoChildId = 'demo-user-david';
  static const String demoChildName = 'David';
  static const String demoDaughterId = 'demo-user-noa';
  static const String demoDaughterName = 'Noa';
  static const String demoGrandparentId = 'demo-user-ruth';
  static const String demoGrandparentName = 'Ruth';
  static const String demoFamilyId = 'demo-family';
  static const String demoInviteCode = 'DEMO01';

  static BackendMode get backendMode => resolveBackendMode(
        backendModeName: backendModeName,
        releaseMode: kReleaseMode,
      );

  static bool get useLocalDemo => backendMode == BackendMode.localDemo;

  static bool get useFirebase => backendMode == BackendMode.firebase;

  /// Store/release Firebase builds. Explicit `BACKEND_MODE=localDemo` on a
  /// release APK stays a development demo build, not production.
  static bool get isProductionBuild =>
      kReleaseMode && backendMode == BackendMode.firebase;

  /// Welcome-screen "Development demo login" and demo family seeding.
  static bool get demoLoginEnabled => useLocalDemo;

  static bool get useEmulator => resolveUseEmulator(
        raw: useEmulatorRaw,
        backendMode: backendMode,
        releaseMode: kReleaseMode,
      );

  /// Phone-auth testing flag. Must never be true outside the emulator.
  static bool get appVerificationDisabledForTesting => useEmulator;

  static BackendMode resolveBackendMode({
    required String backendModeName,
    required bool releaseMode,
  }) {
    switch (backendModeName.trim().toLowerCase()) {
      case 'firebase':
        return BackendMode.firebase;
      case 'localdemo':
      case 'local_demo':
      case 'demo':
        return BackendMode.localDemo;
      case '':
        // Debug stays convenient. Release/store defaults to Firebase so a
        // forgotten dart-define cannot ship the on-device demo.
        return releaseMode ? BackendMode.firebase : BackendMode.localDemo;
      default:
        throw ProductionConfigException(
          'Unknown BACKEND_MODE "$backendModeName". '
          'Use localDemo or firebase.',
        );
    }
  }

  static bool resolveUseEmulator({
    required String raw,
    required BackendMode backendMode,
    required bool releaseMode,
  }) {
    if (releaseMode) return false;
    if (backendMode != BackendMode.firebase) return false;
    if (raw.trim().isEmpty) return true;
    switch (raw.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
      default:
        throw ProductionConfigException(
          'Unknown USE_EMULATOR "$raw". Use true or false.',
        );
    }
  }

  /// Fail closed for production. Does not fall back to local demo.
  static void validateCurrentBuild({
    bool? placeholderFirebase,
    bool? releaseMode,
    BackendMode? mode,
    bool? emulator,
  }) {
    final isRelease = releaseMode ?? kReleaseMode;
    final backend = mode ?? backendMode;
    final useEmu = emulator ?? useEmulator;
    final placeholder =
        placeholderFirebase ?? DefaultFirebaseOptions.isPlaceholder;

    if (isRelease && useEmu) {
      throw const ProductionConfigException(
        'USE_EMULATOR cannot be enabled in a release/store build.',
      );
    }
    if (backend == BackendMode.firebase &&
        useEmu &&
        isRelease) {
      throw const ProductionConfigException(
        'The Firebase emulator cannot be used in production.',
      );
    }
    if (backend == BackendMode.firebase && !useEmu && placeholder) {
      throw const ProductionConfigException(
        'Firebase options are still placeholders. Replace '
        'lib/firebase_options.dart with `flutterfire configure` and add '
        'android/app/google-services.json from the Firebase Console. '
        'MANUAL SETUP REQUIRED — do not invent project IDs or API keys. '
        'This build will not fall back to localDemo.',
      );
    }
  }

  static void assertDemoLoginAllowed() {
    if (!demoLoginEnabled) {
      throw const ProductionConfigException(
        'Development demo login is disabled in this build. '
        'Production uses phone authentication with a real Firebase project.',
      );
    }
  }
}
