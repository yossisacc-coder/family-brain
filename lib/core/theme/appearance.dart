import 'package:flutter/material.dart';

import 'app_accent.dart';
import 'app_colors.dart';

enum AppearanceMode { professional, colorful }

/// Central Family Brain surfaces. Add a new [AppearanceMode] + palette here
/// to introduce another full visual theme without per-widget colors.
class FamilyBrainPalette extends ThemeExtension<FamilyBrainPalette> {
  const FamilyBrainPalette({
    required this.mode,
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
  final Color homeEvents;
  final Color homeEventsSoft;
  final Color homeTasks;
  final Color homeTasksSoft;
  final Color homeReminders;
  final Color homeRemindersSoft;
  final Color homeFamily;
  final Color homeFamilySoft;

  /// Coordinated pastel theme: lavender wash, tinted cards, vivid actions.
  static const colorful = FamilyBrainPalette(
    mode: AppearanceMode.colorful,
    background: Color(0xFFF3EDFF),
    surface: Color(0xFFE9E0FA),
    card: Color(0xFFFCFAFF),
    text: Color(0xFF1B1D29),
    textMuted: Color(0xFF5D5678),
    border: Color(0xFFD9CEF0),
    nav: Color(0xFFF8F4FF),
    desktopBackdrop: Color(0xFFE0D4F4),
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primarySoft: AppColors.primarySoft,
    homeEvents: Color(0xFF7B61FF),
    homeEventsSoft: Color(0xFFEEE6FF),
    homeTasks: Color(0xFF2FA874),
    homeTasksSoft: Color(0xFFE1F6EA),
    homeReminders: Color(0xFFE0893C),
    homeRemindersSoft: Color(0xFFFFF0E0),
    homeFamily: Color(0xFF4C82F0),
    homeFamilySoft: Color(0xFFE4EEFE),
  );

  /// Mature, slightly darker professional theme — still light and readable.
  static const professional = FamilyBrainPalette(
    mode: AppearanceMode.professional,
    background: Color(0xFFE7E5EB),
    surface: Color(0xFFDCD9E2),
    card: Color(0xFFF2F0F4),
    text: Color(0xFF16141F),
    textMuted: Color(0xFF5A5666),
    border: Color(0xFFCBC6D2),
    nav: Color(0xFFEEECF1),
    desktopBackdrop: Color(0xFFD0CCD6),
    primary: Color(0xFF584CC8),
    primaryDark: Color(0xFF3F3698),
    primarySoft: Color(0xFFE4E0F4),
    homeEvents: Color(0xFF5B4FBF),
    homeEventsSoft: Color(0xFFE2DEEC),
    homeTasks: Color(0xFF2F8A68),
    homeTasksSoft: Color(0xFFD5E8DC),
    homeReminders: Color(0xFFB56E32),
    homeRemindersSoft: Color(0xFFEBDCCE),
    homeFamily: Color(0xFF3B6FCF),
    homeFamilySoft: Color(0xFFD7E2F0),
  );

  static FamilyBrainPalette of(
    AppearanceMode mode, {
    AppAccent accent = AppAccent.purple,
  }) {
    final base = mode == AppearanceMode.professional ? professional : colorful;
    final primary = mode == AppearanceMode.professional
        ? Color.lerp(accent.color, const Color(0xFF2A2733), 0.22)!
        : accent.color;
    return base.copyWith(
      primary: primary,
      primaryDark: Color.lerp(primary, const Color(0xFF101018), 0.28)!,
      primarySoft: Color.lerp(primary, base.background, 0.84)!,
    );
  }

  ColorScheme get colorScheme {
    return ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: primaryDark,
      secondary: homeFamily,
      onSecondary: Colors.white,
      secondaryContainer: homeFamilySoft,
      onSecondaryContainer: homeFamily,
      tertiary: homeEvents,
      onTertiary: Colors.white,
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
