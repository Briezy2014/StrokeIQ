import 'package:flutter/material.dart';

import 'swimiq_branded_fallback.dart';
import 'swimiq_branding.dart';

/// Square SwimIQ™ icon for app bar, passport avatar, and compact slots.
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
      fallback: SwimIqBrandedFallback(
        variant: SwimIqBrandedVariant.icon,
        width: size,
        height: size,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Wide branding slot — uses swimiq_icon.png only (Kara: no hero banner asset).
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
    final iconSize = (height * 0.72).clamp(64.0, 160.0);
    return Center(
      child: SwimIqLogo(size: iconSize, borderRadius: borderRadius),
    );
  }
}

class SwimIqWordmark extends StatelessWidget {
  const SwimIqWordmark({
    super.key,
    this.fontSize = 22,
    this.showTm = true,
  });

  final double fontSize;
  final bool showTm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            children: const [
              TextSpan(text: 'SWIM', style: TextStyle(color: Colors.white)),
              TextSpan(
                text: 'IQ',
                style: TextStyle(color: Color(0xFF009CFF)),
              ),
            ],
          ),
        ),
        if (showTm)
          const Padding(
            padding: EdgeInsets.only(top: 2, left: 2),
            child: Text(
              '™',
              style: TextStyle(
                color: Color(0xFF009CFF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
