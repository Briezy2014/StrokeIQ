import 'package:flutter/material.dart';

/// SwimIQ brand colors derived from the Streamlit Athlete Passport design.
class SwimIQColors {
  SwimIQColors._();

  static const primary = Color(0xFF009CFF);
  static const primaryDark = Color(0xFF0B5CAD);
  static const accent = Color(0xFF38B6FF);
  static const surfaceTint = Color(0xFFEAF8FF);
  static const textPrimary = Color(0xFF222222);
  static const textSecondary = Color(0xFF555555);
}

class SwimIQTheme {
  SwimIQTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SwimIQColors.primary,
      primary: SwimIQColors.primary,
      secondary: SwimIQColors.accent,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: SwimIQColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SwimIQColors.primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: SwimIQColors.surfaceTint.withValues(alpha: 0.35),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
