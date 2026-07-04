import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF009CFF);
  static const primaryDark = Color(0xFF0077C8);
  static const primaryDeep = Color(0xFF0B5CAD);
  static const accent = Color(0xFF38B6FF);
  static const surfaceLight = Color(0xFFEAF8FF);
  static const textDark = Color(0xFF0B2D4D);
  static const comingSoonBg = Color(0xFFF3FAFF);
  static const comingSoonBorder = Color(0xFFBFE8FF);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDeep,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: AppColors.surfaceLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          );
        }
        return TextStyle(color: Colors.grey.shade600);
      }),
    ),
  );
}
