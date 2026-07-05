import 'package:flutter/material.dart';

/// Official SwimIQ brand colors from the logo assets.
class SwimIqColors {
  static const black = Color(0xFF000000);
  static const primary = Color(0xFF0055FF);
  static const primaryBright = Color(0xFF007BFF);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF0B2D4D);

  /// Light surfaces for in-app content areas (dashboard cards, forms).
  static const surface = Color(0xFFF4F8FF);
  static const surfaceDark = Color(0xFF101010);
}

ThemeData buildSwimIqTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SwimIqColors.primary,
    brightness: Brightness.light,
    primary: SwimIqColors.primary,
    onPrimary: SwimIqColors.white,
    secondary: SwimIqColors.primaryBright,
    surface: SwimIqColors.white,
    onSurface: SwimIqColors.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SwimIqColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: SwimIqColors.black,
      foregroundColor: SwimIqColors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SwimIqColors.black,
      indicatorColor: SwimIqColors.primary.withValues(alpha: 0.35),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? SwimIqColors.white : Colors.white70,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? SwimIqColors.white : Colors.white70,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SwimIqColors.primary,
      foregroundColor: SwimIqColors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIconColor: SwimIqColors.primaryBright,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: SwimIqColors.primary.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SwimIqColors.primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: SwimIqColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: SwimIqColors.black),
      bodyMedium: TextStyle(color: SwimIqColors.black),
    ),
  );
}

/// Dark theme extension for splash and auth screens on black backgrounds.
ThemeData buildSwimIqDarkAuthTheme(ThemeData base) {
  return base.copyWith(
    scaffoldBackgroundColor: SwimIqColors.black,
    textTheme: base.textTheme.apply(
      bodyColor: SwimIqColors.white,
      displayColor: SwimIqColors.white,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: const Color(0xFF141414),
    ),
  );
}
