import 'package:flutter/material.dart';

import 'appearance.dart';

class AppShadows {
  static List<BoxShadow> cardFor(FamilyBrainPalette palette) {
    if (palette.isDark) {
      return const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ];
    }
    return card;
  }

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A1B1D29),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> phone = [
    BoxShadow(
      color: Color(0x1A1B1D29),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];
}
