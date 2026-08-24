import 'package:flutter/material.dart';

/// Family Brain visual tokens.
///
/// Purple is brand. Blue is the primary action color.
/// Green, orange, and red are reserved for semantic status/priority.
class AppColors {
  static const Color primary = Color(0xFF6B5AED);
  static const Color primaryDark = Color(0xFF4F43C8);
  static const Color primarySoft = Color(0xFFF0EDFF);

  static const Color action = Color(0xFF3B6FE8);
  static const Color actionDark = Color(0xFF2B58C4);
  static const Color actionSoft = Color(0xFFEAF1FE);

  static const Color accent = action;

  static const Color success = Color(0xFF2F9B6E);
  static const Color successSoft = Color(0xFFE6F6EE);

  static const Color high = Color(0xFFE08A2C);
  static const Color highSoft = Color(0xFFFBF0E4);

  static const Color urgent = Color(0xFFD94B4B);
  static const Color urgentSoft = Color(0xFFFBEAEA);

  static const Color info = action;
  static const Color infoSoft = actionSoft;

  static const Color completed = Color(0xFF6E7A76);
  static const Color trash = Color(0xFF7A7F8A);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF6F7FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1B1D29);
  static const Color textMuted = Color(0xFF6A7080);
  static const Color border = Color(0xFFE6E8F0);
  static const Color nav = Color(0xFFFFFFFF);
  static const Color desktopBackdrop = Color(0xFFE8EBF3);
}
