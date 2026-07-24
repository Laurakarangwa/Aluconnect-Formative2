import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const maroon = Color(0xFF7A0F1D);
  const cream = Color(0xFFFFF8F5);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(seedColor: maroon, background: cream, surface: Colors.white),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: maroon,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: maroon),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D4D7))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D4D7))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: maroon, width: 1.6)),
      labelStyle: const TextStyle(color: Color(0xFF7A0F1D)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF7E6E8),
      labelStyle: const TextStyle(color: maroon),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}
