import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'swimiq_branded_fallback.dart';
import 'swimiq_branding.dart';

/// SwimIQ logo at a compact size (app bar, splash, passport avatar).
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
      candidates: SwimIqBranding.logoCandidates,
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

/// Same SwimIQ logo at a larger size (login, headers, app bar brand strip).
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
    return SwimIqBrandedImage(
      candidates: SwimIqBranding.logoCandidates,
      width: double.infinity,
      height: height,
      fit: BoxFit.contain,
      borderRadius: borderRadius,
      fallback: SwimIqBrandedFallback(
        variant: SwimIqBrandedVariant.hero,
        width: double.infinity,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Prominent branding block for auth screens — sits on the gradient, not the white card.
class SwimIqAuthHeader extends StatelessWidget {
  const SwimIqAuthHeader({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050505),
            Color(0xFF0B2D4D),
            Color(0xFF0077C8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SwimIqBrandedImage(
        candidates: SwimIqBranding.logoCandidates,
        width: double.infinity,
        height: height - 32,
        fit: BoxFit.contain,
        borderRadius: 12,
        fallback: SwimIqBrandedFallback(
          variant: SwimIqBrandedVariant.hero,
          width: double.infinity,
          height: height - 32,
          borderRadius: 12,
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
    this.onLightBackground = false,
  });

  final double fontSize;
  final bool showTm;
  final bool onLightBackground;

  @override
  Widget build(BuildContext context) {
    final swimColor =
        onLightBackground ? AppColors.primaryDeep : Colors.white;
    final iqColor = onLightBackground ? AppColors.primary : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            children: [
              TextSpan(text: 'SWIM', style: TextStyle(color: swimColor)),
              TextSpan(text: 'IQ', style: TextStyle(color: iqColor)),
            ],
          ),
        ),
        if (showTm)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 2),
            child: Text(
              '™',
              style: TextStyle(
                color: iqColor,
                fontSize: fontSize * 0.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
