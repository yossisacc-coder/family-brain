import 'dart:io';
import 'dart:ui' as ui;

import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/theme/appearance.dart';
import 'package:family_brain/core/widgets/app_header.dart';
import 'package:family_brain/core/widgets/family_brain_logo.dart';
import 'package:family_brain/data/providers.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ThemeData homeTheme() {
    final palette = FamilyBrainPalette.of(AppearanceMode.colorful);
    return ThemeData(
      useMaterial3: true,
      colorScheme: palette.colorScheme,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
    );
  }
  testWidgets('08E two-tone mark stays clear at 40px', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: FamilyBrainLogoMark(size: 40)),
        ),
      ),
    );
    expect(find.byKey(const Key('family-brain-logo')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('family-brain-logo'))), const Size(40, 40));
  });

  testWidgets('08E app icon is a square that stays clear at 40px', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: FamilyBrainAppIcon(size: 40)),
        ),
      ),
    );
    expect(find.byKey(const Key('family-brain-app-icon')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('family-brain-app-icon'))), const Size(40, 40));
  });

  testWidgets('Home places the 08E lockup in the centered header', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime(2026, 8, 27, 9);
    final user = AppUser(
      id: 'alex',
      name: 'Alex',
      phone: '+10000000001',
      language: 'en',
      createdAt: now,
      familyId: 'fam',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
          familyTasksProvider.overrideWith((ref) => Stream.value(const [])),
          familyMembersProvider.overrideWith((ref) async => [user]),
          unreadCountProvider.overrideWith((ref) => 0),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: homeTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: RepaintBoundary(
              key: Key('home-logo-capture'),
              child: HomeScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lockup = find.byKey(const Key('family-brain-logo-lockup'));
    expect(lockup, findsOneWidget);
    expect(find.byType(FamilyBrainLogoMark), findsWidgets);
    expect(find.textContaining('Family', findRichText: true), findsWidgets);
    expect(find.textContaining('Brain', findRichText: true), findsWidgets);
    expect(find.byType(AppHeader), findsOneWidget);

    final lockupCenter = tester.getCenter(lockup);
    final headerCenter = tester.getCenter(find.byType(AppHeader));
    expect((lockupCenter.dx - headerCenter.dx).abs(), lessThan(8));

    expect(tester.getSize(find.byKey(const Key('family-brain-logo')).first).width, 32);

    final capture = Platform.environment['FAMILY_BRAIN_CAPTURE_LOGO'];
    if (capture != null && capture.isNotEmpty) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('home-logo-capture')),
      );
      final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.png),
      );
      File(capture).writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });

  testWidgets('Home logo lockup does not overflow a narrow phone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime(2026, 8, 27, 9);
    final user = AppUser(
      id: 'alex',
      name: 'Alex',
      phone: '+10000000001',
      language: 'en',
      createdAt: now,
      familyId: 'fam',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
          familyTasksProvider.overrideWith((ref) => Stream.value(const [])),
          familyMembersProvider.overrideWith((ref) async => [user]),
          unreadCountProvider.overrideWith((ref) => 0),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: homeTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('family-brain-logo-lockup')), findsOneWidget);
  });

  testWidgets('08E two-tone wordmark keeps navy Family and azure Brain', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: FamilyBrainLogoLockup(markSize: 40)),
        ),
      ),
    );
    expect(find.byKey(const Key('family-brain-logo-lockup')), findsOneWidget);
    expect(FamilyBrainLogoColors.navy, const Color(0xFF012557));
    expect(FamilyBrainLogoColors.azure, const Color(0xFF0568CA));
  });
}
