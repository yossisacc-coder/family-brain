import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/theme/app_accent.dart';
import 'package:family_brain/core/theme/appearance.dart';
import 'package:family_brain/core/widgets/app_card.dart';
import 'package:family_brain/core/widgets/primary_button.dart';
import 'package:family_brain/core/widgets/secondary_button.dart';
import 'package:family_brain/features/settings/appearance_controller.dart';
import 'package:family_brain/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeData themeWithoutFonts(AppearanceMode mode, {AppAccent accent = AppAccent.purple}) {
  final palette = FamilyBrainPalette.of(mode, accent: accent);
  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: palette.colorScheme,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    extensions: [palette],
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: palette.primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(backgroundColor: palette.card),
    ),
  );
}

void main() {
  test('professional and colorful palettes change surfaces and buttons', () {
    const accent = AppAccent.purple;
    final colorful = FamilyBrainPalette.of(
      AppearanceMode.colorful,
      accent: accent,
    );
    final professional = FamilyBrainPalette.of(
      AppearanceMode.professional,
      accent: accent,
    );

    expect(colorful.background, isNot(equals(professional.background)));
    expect(colorful.card, isNot(equals(professional.card)));
    expect(colorful.surface, isNot(equals(professional.surface)));
    expect(colorful.nav, isNot(equals(professional.nav)));
    expect(colorful.primary, isNot(equals(professional.primary)));
    expect(colorful.colorScheme.surface, colorful.card);
    expect(professional.colorScheme.surface, professional.card);
    expect(colorful.colorScheme.primary, colorful.primary);
    expect(professional.colorScheme.primary, professional.primary);
    expect(colorful.background.computeLuminance(), greaterThan(0.7));
    expect(professional.background.computeLuminance(), greaterThan(0.7));
    expect(colorful.brightness, Brightness.light);
    expect(professional.brightness, Brightness.light);
  });

  test('selected app color tints the whole personal and professional themes', () {
    final purple = FamilyBrainPalette.of(
      AppearanceMode.colorful,
      accent: AppAccent.purple,
    );
    final red = FamilyBrainPalette.of(
      AppearanceMode.colorful,
      accent: AppAccent.red,
    );
    expect(red.background, isNot(equals(purple.background)));
    expect(red.card, isNot(equals(purple.card)));
    expect(red.surface, isNot(equals(purple.surface)));
    expect(red.nav, isNot(equals(purple.nav)));
    expect(red.border, isNot(equals(purple.border)));
    expect(red.primary, AppAccent.red.color);
    expect(
      FamilyBrainPalette.of(
        AppearanceMode.professional,
        accent: AppAccent.red,
      ).background,
      isNot(
        equals(
          FamilyBrainPalette.of(
            AppearanceMode.professional,
            accent: AppAccent.blue,
          ).background,
        ),
      ),
    );
  });

  test('app color still tints primary in both appearance modes', () {
    final blue = FamilyBrainPalette.of(
      AppearanceMode.professional,
      accent: AppAccent.blue,
    );
    final teal = FamilyBrainPalette.of(
      AppearanceMode.professional,
      accent: AppAccent.teal,
    );
    expect(blue.primary, isNot(equals(teal.primary)));
    expect(
      FamilyBrainPalette.of(
        AppearanceMode.colorful,
        accent: AppAccent.teal,
      ).primary,
      AppAccent.teal.color,
    );
  });

  test('appearance selection persists', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppearanceController();
    await controller.setMode(AppearanceMode.professional);
    expect(controller.state, AppearanceMode.professional);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppearanceController.key), 'professional');
  });

  testWidgets(
    'switching appearance changes scaffold, card, and button colors',
    (tester) async {
      Future<({Color scaffold, Color card, Color button})> pump(
        AppearanceMode mode,
      ) async {
        final theme = themeWithoutFonts(mode);
        final palette = theme.extension<FamilyBrainPalette>()!;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            themeMode: ThemeMode.light,
            themeAnimationDuration: Duration.zero,
            home: Scaffold(
              body: Column(
                children: [
                  const AppCard(key: Key('theme-card'), child: Text('card')),
                  PrimaryButton(label: 'Go', onPressed: () {}),
                  SecondaryButton(label: 'Back', onPressed: () {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final cardContext = tester.element(find.byKey(const Key('theme-card')));
        expect(cardContext.palette.card, palette.card);
        expect(cardContext.appColors.surface, palette.card);
        expect(cardContext.appColors.primary, palette.primary);
        expect(
          Theme.of(cardContext).scaffoldBackgroundColor,
          palette.background,
        );
        final cardBox = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(const Key('theme-card')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is DecoratedBox &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).color == palette.card,
            ),
          ),
        );
        expect((cardBox.decoration as BoxDecoration).color, palette.card);
        return (
          scaffold: Theme.of(cardContext).scaffoldBackgroundColor,
          card: cardContext.palette.card,
          button: cardContext.appColors.primary,
        );
      }

      final colorful = await pump(AppearanceMode.colorful);
      final professional = await pump(AppearanceMode.professional);
      expect(colorful.scaffold, isNot(equals(professional.scaffold)));
      expect(colorful.card, isNot(equals(professional.card)));
      expect(colorful.button, isNot(equals(professional.button)));
    },
  );

  testWidgets('Settings appearance control persists the selected theme', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final appearance = ref.watch(appearanceControllerProvider);
            return MaterialApp(
              locale: const Locale('en'),
              theme: themeWithoutFonts(appearance),
              themeAnimationDuration: Duration.zero,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsScreen(publicMode: true),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    await tester.ensureVisible(find.text(l10n.appearanceProfessional));
    await tester.tap(find.text(l10n.appearanceProfessional));
    await tester.pumpAndSettle();

    final after = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(
      after.scaffoldBackgroundColor,
      isNot(equals(before.scaffoldBackgroundColor)),
    );
    expect(after.colorScheme.surface, isNot(equals(before.colorScheme.surface)));
    expect(after.colorScheme.primary, isNot(equals(before.colorScheme.primary)));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppearanceController.key), 'professional');
  });
}
