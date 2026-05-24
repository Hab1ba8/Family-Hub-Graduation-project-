import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Appcolor {
  // ── Brand colors ──
  static const Color primaryColor = Color.fromARGB(255, 76, 175, 175);
  static const Color secondaryColor = Color.fromARGB(255, 204, 189, 123);

  // ── Food‑module teal (aligned with app theme) ──
  static Color get foodPrimary => AppColors.primary;
  static Color get foodPrimaryLight => AppColors.primaryLight;
  static Color get foodPrimaryDark => AppColors.dark;
  static Color get foodBg => AppColors.background;
  static Color get foodCardBg => AppColors.primarySurface;
  static Color get foodAccent => AppColors.textSecondary;

  // ── Neutral text ──
  static const Color textDark = Color(0xFF00352E);
  static const Color textMedium = Color(0xFF616161);
  static const Color textLight = Color(0xFF9E9E9E);

  // ── Status / semantic ──
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static Color get success => AppColors.primary;

  // ── Category card palette (10 colours, indexed) ──
  static List<Color> get categoryColors => [
    AppColors.primary,
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFF44336),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFFFF5722),
  ];
}
 