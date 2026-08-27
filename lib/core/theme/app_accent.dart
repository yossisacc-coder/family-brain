import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import 'app_colors.dart';

/// Selectable app accent/primary. Surfaces, cards, and chrome follow this color.
enum AppAccent {
  purple,
  blue,
  green,
  orange,
  red,
  pink,
  teal,
  indigo,
  cyan,
  slate,
  coral,
}

extension AppAccentColors on AppAccent {
  Color get color => switch (this) {
        AppAccent.purple => AppColors.primary,
        AppAccent.blue => const Color(0xFF3B6FE8),
        AppAccent.green => const Color(0xFF2F9B6E),
        AppAccent.orange => const Color(0xFFE07A2F),
        AppAccent.red => const Color(0xFFD64545),
        AppAccent.pink => const Color(0xFFD4538A),
        AppAccent.teal => const Color(0xFF1A9B8A),
        AppAccent.indigo => const Color(0xFF4F46E5),
        AppAccent.cyan => const Color(0xFF0891B2),
        AppAccent.slate => const Color(0xFF4B6280),
        AppAccent.coral => const Color(0xFFE05A4F),
      };

  Color get dark => Color.lerp(color, const Color(0xFF101018), 0.28)!;

  Color get soft => Color.lerp(color, Colors.white, 0.88)!;

  String label(AppLocalizations l10n) => switch (this) {
        AppAccent.purple => l10n.colorPurple,
        AppAccent.blue => l10n.colorBlue,
        AppAccent.green => l10n.colorGreen,
        AppAccent.orange => l10n.colorOrange,
        AppAccent.red => l10n.colorRed,
        AppAccent.pink => l10n.colorPink,
        AppAccent.teal => l10n.colorTeal,
        AppAccent.indigo => l10n.colorIndigo,
        AppAccent.cyan => l10n.colorCyan,
        AppAccent.slate => l10n.colorSlate,
        AppAccent.coral => l10n.colorCoral,
      };

  static AppAccent fromName(String? name) {
    return AppAccent.values.where((value) => value.name == name).firstOrNull ??
        AppAccent.purple;
  }
}
