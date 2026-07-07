import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_colors.dart';

/// Cursive tagline matching Aspyn's logo feel — "Built in the Water…"
class SwimIqTagline extends StatelessWidget {
  const SwimIqTagline({
    super.key,
    this.fontSize = 22,
    this.color,
    this.textAlign = TextAlign.center,
  });

  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppConstants.tagline,
      textAlign: textAlign,
      style: GoogleFonts.pacifico(
        fontSize: fontSize,
        height: 1.35,
        color: color ?? AppColors.primaryDeep,
        shadows: color == Colors.white || color == null
            ? null
            : [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
    );
  }
}

/// "Founded by Aspyn Briez" — secondary brand line.
class SwimIqFounderLine extends StatelessWidget {
  const SwimIqFounderLine({
    super.key,
    this.color,
    this.fontSize = 13,
  });

  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppConstants.founder,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color ?? AppColors.textSecondary,
      ),
    );
  }
}
