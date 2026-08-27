import 'package:flutter/material.dart';

import 'app_accent.dart';
import 'app_colors.dart';

enum AppearanceMode { professional, colorful }

/// Switchable Home/chrome tints. Semantic task colors stay on [AppColors].
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

  static const colorful = FamilyBrainPalette(
    mode: AppearanceMode.colorful,
    background: AppColors.background,
    surface: AppColors.surface,
    card: AppColors.card,
    text: AppColors.text,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    nav: AppColors.nav,
    desktopBackdrop: AppColors.desktopBackdrop,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primarySoft: AppColors.primarySoft,
    homeEvents: AppColors.homeEvents,
    homeEventsSoft: AppColors.homeEventsSoft,
    homeTasks: AppColors.homeTasks,
    homeTasksSoft: AppColors.homeTasksSoft,
    homeReminders: AppColors.homeReminders,
    homeRemindersSoft: AppColors.homeRemindersSoft,
    homeFamily: AppColors.homeFamily,
    homeFamilySoft: AppColors.homeFamilySoft,
  );

  /// Slightly darker, mature pastels — not a full dark theme.
  static const professional = FamilyBrainPalette(
    mode: AppearanceMode.professional,
    background: Color(0xFFF3F1F6),
    surface: Color(0xFFE8E5EE),
    card: Color(0xFFF7F6FA),
    text: Color(0xFF16141F),
    textMuted: Color(0xFF5C5868),
    border: Color(0xFFD9D5E3),
    nav: Color(0xFFF7F6FA),
    desktopBackdrop: Color(0xFFDCD8E4),
    primary: Color(0xFF584CC8),
    primaryDark: Color(0xFF3F3698),
    primarySoft: Color(0xFFE4E0F4),
    homeEvents: Color(0xFF5B4FBF),
    homeEventsSoft: Color(0xFFE6E2F4),
    homeTasks: Color(0xFF2F8A68),
    homeTasksSoft: Color(0xFFD8EBDF),
    homeReminders: Color(0xFFC47B36),
    homeRemindersSoft: Color(0xFFF3E4D3),
    homeFamily: Color(0xFF3B6FCF),
    homeFamilySoft: Color(0xFFDCE6F6),
  );

  static FamilyBrainPalette of(
    AppearanceMode mode, {
    AppAccent accent = AppAccent.purple,
  }) {
    final base = mode == AppearanceMode.professional ? professional : colorful;
    return base.copyWith(
      primary: accent.color,
      primaryDark: accent.dark,
      primarySoft: accent.soft,
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
}
