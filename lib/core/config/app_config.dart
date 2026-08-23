/// Runtime configuration for Family Brain.
///
/// Production uses a real Firebase project. Local development defaults to the
/// Firebase Emulator Suite so the MVP can run without paid SMS or owner
/// credentials during this first build.
class AppConfig {
  static const String appName = 'Family Brain';
  static const String version = '1.0.0';

  /// Family is the first workspace type on a platform that can grow later.
  static const String defaultWorkspaceType = 'family';

  static const bool useEmulator = bool.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: true,
  );

  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8088;

  static const String demoPhone = '+16505551234';
  static const String demoOtp = '123456';
  static const String demoName = 'Alex';
}
