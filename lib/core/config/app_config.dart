/// Runtime configuration for Family Brain.
///
/// Default APK/device builds use an on-device local demo backend so Home,
/// Family, Tasks, Notifications, and language/RTL can be tested without SMS
/// or production Firebase. The Phone/OTP + Firebase architecture is unchanged
/// and is selected with `--dart-define=BACKEND_MODE=firebase`.
///
/// Cloud AI (Gemini / Google AI Studio) is not wired in this MVP: there is no
/// secure backend to hold an API key, and keys must not be shipped in the
/// Flutter client. Family Brain understanding uses the on-device parser.
enum BackendMode { localDemo, firebase }

class AppConfig {
  static const String appName = 'Family Brain';
  static const String version = '1.1.0';

  /// Family is the first workspace type on a platform that can grow later.
  static const String defaultWorkspaceType = 'family';

  static const String backendModeName = String.fromEnvironment(
    'BACKEND_MODE',
    defaultValue: 'localDemo',
  );

  static BackendMode get backendMode {
    switch (backendModeName) {
      case 'firebase':
        return BackendMode.firebase;
      default:
        return BackendMode.localDemo;
    }
  }

  static bool get useLocalDemo => backendMode == BackendMode.localDemo;

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
  static const String demoPartnerName = 'Maya';
  static const String demoFamilyName = 'The Cohens';
  static const String demoUserId = 'demo-user-alex';
  static const String demoPartnerId = 'demo-user-maya';
  static const String demoFamilyId = 'demo-family';
  static const String demoInviteCode = 'DEMO01';
}
