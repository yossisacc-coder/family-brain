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

  /// Friendly light theme: clean white base, selected color throughout.
  static FamilyBrainPalette _personal(Color seed) {
    final background = Color.lerp(const Color(0xFFFFFFFF), seed, 0.07)!;
    final surface = Color.lerp(const Color(0xFFF7F6FB), seed, 0.12)!;
    final card = Color.lerp(const Color(0xFFFFFFFF), seed, 0.03)!;
    final nav = Color.lerp(const Color(0xFFFFFFFF), seed, 0.06)!;
    final border = Color.lerp(const Color(0xFFE4E2EA), seed, 0.32)!;
    final text = const Color(0xFF1B1D29);
    final textMuted = Color.lerp(const Color(0xFF667085), seed, 0.14)!;
    final primary = seed;
    final primaryDark = Color.lerp(seed, const Color(0xFF101018), 0.28)!;
    final primarySoft = Color.lerp(seed, const Color(0xFFFFFFFF), 0.86)!;
    return FamilyBrainPalette(
      mode: AppearanceMode.colorful,
      brightness: Brightness.light,
      background: background,
      surface: surface,
      card: card,
      text: text,
      textMuted: textMuted,
      border: border,
      nav: nav,
      desktopBackdrop: Color.lerp(const Color(0xFFE8EBF3), seed, 0.18)!,
      primary: primary,
      primaryDark: primaryDark,
      primarySoft: primarySoft,
      onPrimary: Colors.white,
      homeEvents: Color.lerp(const Color(0xFF7B61FF), seed, 0.32)!,
      homeEventsSoft: Color.lerp(const Color(0xFFEEE6FF), seed, 0.18)!,
      homeTasks: Color.lerp(const Color(0xFF2FA874), seed, 0.28)!,
      homeTasksSoft: Color.lerp(const Color(0xFFE1F6EA), seed, 0.16)!,
      homeReminders: Color.lerp(const Color(0xFFE0893C), seed, 0.28)!,
      homeRemindersSoft: Color.lerp(const Color(0xFFFFF0E0), seed, 0.16)!,
      homeFamily: Color.lerp(const Color(0xFF4C82F0), seed, 0.28)!,
      homeFamilySoft: Color.lerp(const Color(0xFFE4EEFE), seed, 0.16)!,
    );
  }

  /// Darker, higher-contrast workspace using the same color family.
  static FamilyBrainPalette _professional(Color seed) {
    final background = Color.lerp(const Color(0xFF121018), seed, 0.20)!;
    final surface = Color.lerp(const Color(0xFF1A1822), seed, 0.24)!;
    final card = Color.lerp(const Color(0xFF24212C), seed, 0.22)!;
    final nav = Color.lerp(const Color(0xFF18161F), seed, 0.18)!;
    final border = Color.lerp(const Color(0xFF3C3848), seed, 0.30)!;
    final text = const Color(0xFFF4F2F8);
    final textMuted = Color.lerp(const Color(0xFFB8B3C4), seed, 0.12)!;
    final primary = Color.lerp(seed, const Color(0xFFFFFFFF), 0.12)!;
    final primaryDark = Color.lerp(seed, const Color(0xFF000000), 0.22)!;
    final primarySoft = Color.lerp(seed, background, 0.62)!;
    return FamilyBrainPalette(
      mode: AppearanceMode.professional,
      brightness: Brightness.dark,
      background: background,
      surface: surface,
      card: card,
      text: text,
      textMuted: textMuted,
      border: border,
      nav: nav,
      desktopBackdrop: Color.lerp(const Color(0xFF0C0B10), seed, 0.14)!,
      primary: primary,
      primaryDark: primaryDark,
      primarySoft: primarySoft,
      onPrimary: Colors.white,
      homeEvents: Color.lerp(const Color(0xFF9B89FF), seed, 0.40)!,
      homeEventsSoft: Color.lerp(card, const Color(0xFF7B61FF), 0.22)!,
      homeTasks: Color.lerp(const Color(0xFF3FBF88), seed, 0.32)!,
      homeTasksSoft: Color.lerp(card, const Color(0xFF2FA874), 0.22)!,
      homeReminders: Color.lerp(const Color(0xFFE39A55), seed, 0.32)!,
      homeRemindersSoft: Color.lerp(card, const Color(0xFFE0893C), 0.22)!,
      homeFamily: Color.lerp(const Color(0xFF6A9AFF), seed, 0.32)!,
      homeFamilySoft: Color.lerp(card, const Color(0xFF4C82F0), 0.22)!,
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
