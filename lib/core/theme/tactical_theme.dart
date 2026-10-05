import 'package:flutter/material.dart';

class TacticalTheme {
  TacticalTheme._();

  // Palette
  static const Color background = Color(0xFF0F172A); // Deep slate
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);

  static const Color playerHero = Color(0xFF38BDF8); // Cyan neon
  static const Color playerEnemy = Color(0xFFF43F5E); // Crimson neon

  // Elemental Colors
  static const Color cryoIce = Color(0xFF67E8F9);
  static const Color magmaLava = Color(0xFFF97316);
  static const Color portalViolet = Color(0xFFA855F7);
  static const Color teslaGold = Color(0xFFFACC15);
  static const Color stoneRuin = Color(0xFF94A3B8);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: playerHero,
      secondary: magmaLava,
      surface: surface,
    ),
    fontFamily: 'sans-serif',
  );
}
