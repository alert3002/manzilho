import 'package:flutter/material.dart';

const manzilhoBlue = Color(0xFF1A3C55);
const manzilhoOrange = Color(0xFFE79A3E);

ThemeData buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: manzilhoBlue,
      brightness: Brightness.light,
      primary: manzilhoBlue,
      secondary: manzilhoOrange,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: manzilhoBlue,
      brightness: Brightness.dark,
      primary: manzilhoOrange,
      secondary: manzilhoOrange,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF0a0a0a),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2c2c2c),
      foregroundColor: Color(0xFFE5E7EB),
      elevation: 0,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: const Color(0xFF171717),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
  );
}

