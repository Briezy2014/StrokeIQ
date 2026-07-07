import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'swimiq_branding.dart';
import 'swimiq_brand_typography.dart';

/// Login / signup header: logo + cursive tagline (+ optional title).
class SwimIqAuthHeader extends StatelessWidget {
  const SwimIqAuthHeader({
    super.key,
    this.title,
    this.logoSize = 96,
  });

  final String? title;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SwimIqLogo(size: logoSize, borderRadius: logoSize * 0.22),
        ),
        const SizedBox(height: 20),
        const SwimIqTagline(fontSize: 20),
        const SizedBox(height: 8),
        const SwimIqFounderLine(),
        if (title != null) ...[
          const SizedBox(height: 20),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0B2D4D),
            ),
          ),
        ],
      ],
    );
  }
}

/// Square SwimIQ™ icon — loads uploaded PNG from assets/branding/ when present.
class SwimIqLogo extends StatelessWidget {
  const SwimIqLogo({
    super.key,
    this.size = 72,
    this.borderRadius = 16,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SwimIqBrandedImage(
      candidates: SwimIqBranding.iconCandidates,
      width: size,
      height: size,
      fit: BoxFit.contain,
      borderRadius: borderRadius,
      fallback: SwimIqBrandMark(size: size, borderRadius: borderRadius),
    );
  }
}

/// Painted fallback when swimiq_icon.png is not in assets yet.
class SwimIqBrandMark extends StatelessWidget {
  const SwimIqBrandMark({
    super.key,
    required this.size,
    this.borderRadius = 16,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2D4D),
            Color(0xFF0B5CAD),
            Color(0xFF009CFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B5CAD).withValues(alpha: 0.35),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.06),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waves, color: Colors.white, size: size * 0.28),
          SizedBox(height: size * 0.04),
          SwimIqWordmark(fontSize: size * 0.17, onDark: true),
        ],
      ),
    );
  }
}

/// Wide SwimIQ™ hero banner (logo + tagline) for welcome and passport hero.
class SwimIqHeroBanner extends StatelessWidget {
  const SwimIqHeroBanner({
    super.key,
    this.height = 140,
    this.borderRadius = 20,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2D4D),
            Color(0xFF0B5CAD),
            Color(0xFF009CFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B5CAD).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SwimIqBrandedImage(
        candidates: SwimIqBranding.heroCandidates,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        borderRadius: 0,
        fallback: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SwimIqWordmark(fontSize: 28, onDark: true),
              const SizedBox(height: 6),
              SwimIqTagline(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwimIqWordmark extends StatelessWidget {
  const SwimIqWordmark({
    super.key,
    this.fontSize = 22,
    this.showTm = true,
    this.onDark = false,
  });

  final double fontSize;
  final bool showTm;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final swimColor = onDark ? Colors.white : const Color(0xFF0B2D4D);
    final iqColor = onDark ? const Color(0xFF5CC8FF) : const Color(0xFF009CFF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
            children: [
              TextSpan(text: 'SWIM', style: TextStyle(color: swimColor)),
              TextSpan(text: 'IQ', style: TextStyle(color: iqColor)),
            ],
          ),
        ),
        if (showTm)
          Padding(
            padding: EdgeInsets.only(top: fontSize * 0.08, left: 2),
            child: Text(
              '™',
              style: GoogleFonts.outfit(
                color: iqColor,
                fontSize: fontSize * 0.38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
