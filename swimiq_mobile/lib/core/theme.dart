import 'package:flutter/material.dart';

/// SwimIQ brand colors taken from the existing Streamlit Athlete Passport UI.
class SwimIqColors {
  static const primary = Color(0xFF009CFF);
  static const primaryDark = Color(0xFF0077C8);
  static const navy = Color(0xFF0B2D4D);
  static const lightBlue = Color(0xFFEAF8FF);
}

ThemeData buildSwimIqTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SwimIqColors.primary,
    primary: SwimIqColors.primary,
    secondary: SwimIqColors.primaryDark,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SwimIqColors.lightBlue,
    appBarTheme: const AppBarTheme(
      backgroundColor: SwimIqColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SwimIqColors.primary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
