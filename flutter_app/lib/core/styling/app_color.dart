import 'package:flutter/material.dart';

class Appcolor {
  // ── Brand colors ──
  static const Color primaryColor = Color.fromARGB(255, 76, 175, 175);
  static const Color secondaryColor = Color.fromARGB(255, 204, 189, 123);

  // ── Food‑module teal (aligned with app theme) ──
  static const Color foodPrimary = Color(0xFF00897B);
  static const Color foodPrimaryLight = Color(0xFF00ACC1);
  static const Color foodPrimaryDark = Color(0xFF00695C);
  static const Color foodBg = Color(0xFFE8F5F5);
  static const Color foodCardBg = Color(0xFFE0F2F1);
  static const Color foodAccent = Color(0xFF4DB6AC);

  // ── Neutral text ──
  static const Color textDark = Color(0xFF00352E);
  static const Color textMedium = Color(0xFF616161);
  static const Color textLight = Color(0xFF9E9E9E);

  // ── Status / semantic ──
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color success = Color(0xFF00897B);

  // ── Category card palette (10 colours, indexed) ──
  static const List<Color> categoryColors = [
    Color(0xFF00897B),
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
 