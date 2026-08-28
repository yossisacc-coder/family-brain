import 'package:family_brain/core/config/app_config.dart';
import 'package:family_brain/core/config/production_config_exception.dart';
import 'package:family_brain/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveBackendMode', () {
    test('debug without dart-define stays local demo', () {
      expect(
        AppConfig.resolveBackendMode(
          backendModeName: '',
          releaseMode: false,
        ),
        BackendMode.localDemo,
      );
    });

    test('release without dart-define defaults to firebase', () {
      expect(
        AppConfig.resolveBackendMode(
          backendModeName: '',
          releaseMode: true,
        ),
        BackendMode.firebase,
      );
    });

    test('explicit localDemo works in debug', () {
      expect(
        AppConfig.resolveBackendMode(
          backendModeName: 'localDemo',
          releaseMode: false,
        ),
        BackendMode.localDemo,
      );
    });

    test('explicit firebase works in debug', () {
      expect(
        AppConfig.resolveBackendMode(
          backendModeName: 'firebase',
          releaseMode: false,
        ),
        BackendMode.firebase,
      );
    });

    test('unknown BACKEND_MODE fails closed', () {
      expect(
        () => AppConfig.resolveBackendMode(
          backendModeName: 'mystery',
          releaseMode: false,
        ),
        throwsA(isA<ProductionConfigException>()),
      );
    });
  });

  group('resolveUseEmulator', () {
    test('release never enables the emulator', () {
      expect(
        AppConfig.resolveUseEmulator(
          raw: 'true',
          backendMode: BackendMode.firebase,
          releaseMode: true,
        ),
        isFalse,
      );
    });

    test('local demo does not use the emulator', () {
      expect(
        AppConfig.resolveUseEmulator(
          raw: '',
          backendMode: BackendMode.localDemo,
          releaseMode: false,
        ),
        isFalse,
      );
    });

    test('firebase debug defaults to emulator on', () {
      expect(
        AppConfig.resolveUseEmulator(
          raw: '',
          backendMode: BackendMode.firebase,
          releaseMode: false,
        ),
        isTrue,
      );
    });

    test('firebase debug can turn the emulator off', () {
      expect(
        AppConfig.resolveUseEmulator(
          raw: 'false',
          backendMode: BackendMode.firebase,
          releaseMode: false,
        ),
        isFalse,
      );
    });
  });

  group('validateCurrentBuild', () {
    test('production firebase with placeholder options fails closed', () {
      expect(
        () => AppConfig.validateCurrentBuild(
          placeholderFirebase: true,
          releaseMode: true,
          mode: BackendMode.firebase,
          emulator: false,
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (error) => error.message,
            'message',
            contains('will not fall back to localDemo'),
          ),
        ),
      );
    });

    test('production cannot enable the emulator', () {
      expect(
        () => AppConfig.validateCurrentBuild(
          placeholderFirebase: false,
          releaseMode: true,
          mode: BackendMode.firebase,
          emulator: true,
        ),
        throwsA(isA<ProductionConfigException>()),
      );
    });

    test('debug local demo is allowed with placeholder Firebase', () {
      expect(
        () => AppConfig.validateCurrentBuild(
          placeholderFirebase: true,
          releaseMode: false,
          mode: BackendMode.localDemo,
          emulator: false,
        ),
        returnsNormally,
      );
    });

    test('firebase emulator debug is allowed with placeholder options', () {
      expect(
        () => AppConfig.validateCurrentBuild(
          placeholderFirebase: true,
          releaseMode: false,
          mode: BackendMode.firebase,
          emulator: true,
        ),
        returnsNormally,
      );
    });
  });

  test('committed Firebase options are still placeholders', () {
    expect(DefaultFirebaseOptions.isPlaceholder, isTrue);
    expect(DefaultFirebaseOptions.hasRealConfiguration, isFalse);
  });

  test('this test process is a development build', () {
    expect(AppConfig.useLocalDemo, isTrue);
    expect(AppConfig.demoLoginEnabled, isTrue);
    expect(AppConfig.isProductionBuild, isFalse);
    expect(AppConfig.useEmulator, isFalse);
    expect(AppConfig.appVerificationDisabledForTesting, isFalse);
  });
}
