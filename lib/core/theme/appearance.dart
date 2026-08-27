import 'package:flutter/material.dart';

import 'app_accent.dart';
import 'app_colors.dart';

enum AppearanceMode { professional, colorful }

extension AppearanceModeVisual on AppearanceMode {
  bool get isProfessional => this == AppearanceMode.professional;
  bool get isPersonal => this == AppearanceMode.colorful;
}

/// Central Family Brain surfaces. Add a new [AppearanceMode] + palette here
/// to introduce another full visual theme without per-widget colors.
class FamilyBrainPalette extends ThemeExtension<FamilyBrainPalette> {
  const FamilyBrainPalette({
    required this.mode,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.card,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.nav,
    required this.desktopBackdrop,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.onPrimary,
    required this.homeEvents,
    required this.homeEventsSoft,
    required this.homeTasks,
    required this.homeTasksSoft,
    required this.homeReminders,
    required this.homeRemindersSoft,
    required this.homeFamily,
    required this.homeFamilySoft,
  });

  final AppearanceMode mode;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color card;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color nav;
  final Color desktopBackdrop;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color onPrimary;
  final Color homeEvents;
  final Color homeEventsSoft;
  final Color homeTasks;
  final Color homeTasksSoft;
  final Color homeReminders;
  final Color homeRemindersSoft;
  final Color homeFamily;
  final Color homeFamilySoft;

  bool get isDark => brightness == Brightness.dark;

  /// Personal / original Family Brain identity (purple, clean white).
  static final colorful = of(AppearanceMode.colorful);

  /// Professional companion of the default purple family.
  static final professional = of(AppearanceMode.professional);

  static FamilyBrainPalette of(
    AppearanceMode mode, {
    AppAccent accent = AppAccent.purple,
  }) {
    final seed = accent.color;
    if (mode == AppearanceMode.professional) {
      return _professional(seed);
    }
    return _personal(seed);
  }

  /// Mix [seed] into a light base so each app color has its own surfaces.
  static Color _tint(Color base, Color seed, double amount) =>
      Color.lerp(base, seed, amount)!;

  /// Friendly light theme: clean white/light surfaces with a seed-tinted family.
  static FamilyBrainPalette _personal(Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return FamilyBrainPalette(
      mode: AppearanceMode.colorful,
      brightness: Brightness.light,
      background: _tint(const Color(0xFFF8F7FB), seed, 0.08),
      surface: _tint(const Color(0xFFF3F2F8), seed, 0.10),
      card: _tint(const Color(0xFFFFFFFF), seed, 0.045),
      text: scheme.onSurface,
      textMuted: scheme.onSurfaceVariant,
      border: _tint(const Color(0xFFE6E4EE), seed, 0.22),
      nav: _tint(const Color(0xFFFFFFFF), seed, 0.07),
      desktopBackdrop: _tint(const Color(0xFFEEEAF6), seed, 0.10),
      primary: seed,
      primaryDark: Color.lerp(seed, const Color(0xFF101018), 0.28)!,
      primarySoft: scheme.primaryContainer,
      onPrimary: seed.computeLuminance() > 0.55
          ? const Color(0xFF1B1D29)
          : Colors.white,
      homeEvents: Color.lerp(const Color(0xFF7B61FF), seed, 0.38)!,
      homeEventsSoft: Color.lerp(scheme.primaryContainer, const Color(0xFFEEE6FF), 0.45)!,
      homeTasks: Color.lerp(const Color(0xFF2FA874), seed, 0.32)!,
      homeTasksSoft: Color.lerp(scheme.primaryContainer, const Color(0xFFE1F6EA), 0.45)!,
      homeReminders: Color.lerp(const Color(0xFFE0893C), seed, 0.32)!,
      homeRemindersSoft: Color.lerp(scheme.primaryContainer, const Color(0xFFFFF0E0), 0.45)!,
      homeFamily: Color.lerp(const Color(0xFF4C82F0), seed, 0.32)!,
      homeFamilySoft: Color.lerp(scheme.primaryContainer, const Color(0xFFE4EEFE), 0.45)!,
    );
  }

  /// Darker, higher-contrast workspace using the same color family.
  static FamilyBrainPalette _professional(Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return FamilyBrainPalette(
      mode: AppearanceMode.professional,
      brightness: Brightness.dark,
      background: Color.lerp(const Color(0xFF12141C), seed, 0.16)!,
      surface: Color.lerp(scheme.surfaceContainer, seed, 0.10)!,
      card: Color.lerp(scheme.surfaceContainerHigh, seed, 0.08)!,
      text: scheme.onSurface,
      textMuted: scheme.onSurfaceVariant,
      border: scheme.outlineVariant,
      nav: scheme.surfaceContainerLow,
      desktopBackdrop: scheme.surfaceContainerLowest,
      primary: Color.lerp(seed, const Color(0xFFFFFFFF), 0.16)!,
      primaryDark: Color.lerp(seed, const Color(0xFF000000), 0.18)!,
      primarySoft: scheme.primaryContainer,
      onPrimary: scheme.onPrimary,
      homeEvents: Color.lerp(const Color(0xFF9B89FF), seed, 0.40)!,
      homeEventsSoft: Color.lerp(scheme.surfaceContainerHigh, const Color(0xFF7B61FF), 0.22)!,
      homeTasks: Color.lerp(const Color(0xFF3FBF88), seed, 0.32)!,
      homeTasksSoft: Color.lerp(scheme.surfaceContainerHigh, const Color(0xFF2FA874), 0.22)!,
      homeReminders: Color.lerp(const Color(0xFFE39A55), seed, 0.32)!,
      homeRemindersSoft: Color.lerp(scheme.surfaceContainerHigh, const Color(0xFFE0893C), 0.22)!,
      homeFamily: Color.lerp(const Color(0xFF6A9AFF), seed, 0.32)!,
      homeFamilySoft: Color.lerp(scheme.surfaceContainerHigh, const Color(0xFF4C82F0), 0.22)!,
    );
  }

  ColorScheme get colorScheme {
    if (isDark) {
      return ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primarySoft,
        onPrimaryContainer: text,
        secondary: homeFamily,
        onSecondary: onPrimary,
        secondaryContainer: homeFamilySoft,
        onSecondaryContainer: homeFamily,
        tertiary: homeEvents,
        onTertiary: onPrimary,
        tertiaryContainer: homeEventsSoft,
        onTertiaryContainer: homeEvents,
        surface: card,
        onSurface: text,
        onSurfaceVariant: textMuted,
        error: AppColors.urgent,
        onError: Colors.white,
        outline: border,
        outlineVariant: border,
        surfaceContainerLowest: background,
        surfaceContainerLow: surface,
        surfaceContainer: card,
        surfaceContainerHigh: nav,
        surfaceContainerHighest: surface,
      );
    }
    return ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primarySoft,
      onPrimaryContainer: primaryDark,
      secondary: homeFamily,
      onSecondary: onPrimary,
      secondaryContainer: homeFamilySoft,
      onSecondaryContainer: homeFamily,
      tertiary: homeEvents,
      onTertiary: onPrimary,
      tertiaryContainer: homeEventsSoft,
      onTertiaryContainer: homeEvents,
      surface: card,
      onSurface: text,
      onSurfaceVariant: textMuted,
      error: AppColors.urgent,
      onError: Colors.white,
      outline: border,
      outlineVariant: border,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: card,
      surfaceContainerHigh: nav,
      surfaceContainerHighest: surface,
    );
  }

  @override
  FamilyBrainPalette copyWith({
    AppearanceMode? mode,
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? card,
    Color? text,
    Color? textMuted,
    Color? border,
    Color? nav,
    Color? desktopBackdrop,
    Color? primary,
    Color? primaryDark,
    Color? primarySoft,
    Color? onPrimary,
    Color? homeEvents,
    Color? homeEventsSoft,
    Color? homeTasks,
    Color? homeTasksSoft,
    Color? homeReminders,
    Color? homeRemindersSoft,
    Color? homeFamily,
    Color? homeFamilySoft,
  }) {
    return FamilyBrainPalette(
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      nav: nav ?? this.nav,
      desktopBackdrop: desktopBackdrop ?? this.desktopBackdrop,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      homeEvents: homeEvents ?? this.homeEvents,
      homeEventsSoft: homeEventsSoft ?? this.homeEventsSoft,
      homeTasks: homeTasks ?? this.homeTasks,
      homeTasksSoft: homeTasksSoft ?? this.homeTasksSoft,
      homeReminders: homeReminders ?? this.homeReminders,
      homeRemindersSoft: homeRemindersSoft ?? this.homeRemindersSoft,
      homeFamily: homeFamily ?? this.homeFamily,
      homeFamilySoft: homeFamilySoft ?? this.homeFamilySoft,
    );
  }

  @override
  FamilyBrainPalette lerp(ThemeExtension<FamilyBrainPalette>? other, double t) {
    if (other is! FamilyBrainPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension FamilyBrainPaletteContext on BuildContext {
  FamilyBrainPalette get palette =>
      Theme.of(this).extension<FamilyBrainPalette>() ??
      FamilyBrainPalette.colorful;

  ColorScheme get appColors => Theme.of(this).colorScheme;
}
