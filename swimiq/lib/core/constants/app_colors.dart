import 'package:flutter/material.dart';

/// SwimIQ brand palette — deep pool blue, bright lane-line cyan, soft water surfaces.
abstract final class AppColors {
  static const Color primary = Color(0xFF0B5CAD);
  static const Color primaryDark = Color(0xFF0077C8);
  static const Color primaryDeep = Color(0xFF0B2D4D);
  static const Color accent = Color(0xFF009CFF);
  static const Color accentLight = Color(0xFF38B6FF);
  static const Color accentBright = Color(0xFF5CC8FF);
  static const Color surfaceLight = Color(0xFFEAF8FF);
  static const Color background = Color(0xFFF3FAFF);
  static const Color backgroundMid = Color(0xFFD6F0FF);
  static const Color surface = Color(0xFFF8FCFF);
  static const Color surfaceGlass = Color(0xF2FFFFFF);
  static const Color textPrimary = Color(0xFF0B2D4D);
  static const Color textSecondary = Color(0xFF3D5A73);
  static const Color textDark = textPrimary;
  static const Color comingSoonBg = Color(0xFFF3FAFF);
  static const Color comingSoonBorder = Color(0xFFBFE8FF);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B5CAD),
      Color(0xFF009CFF),
      Color(0xFF38B6FF),
      Color(0xFFE8F7FF),
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B2D4D),
      Color(0xFF0B5CAD),
      Color(0xFF009CFF),
    ],
  );

  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF0F9FF),
    ],
  );
}
