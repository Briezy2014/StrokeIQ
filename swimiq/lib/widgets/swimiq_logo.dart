import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'swimiq_branded_fallback.dart';
import 'swimiq_branding.dart';

/// Small slot: swimmer mark only (zooms full lockup PNG to the icon region).
class SwimIqCompactMark extends StatelessWidget {
  const SwimIqCompactMark({
    super.key,
    this.size = 48,
    this.borderRadius = 12,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SwimIqBrandedImage(
          candidates: SwimIqBranding.compactCandidates,
          width: size,
          height: size,
          fit: BoxFit.contain,
          zoomToMark: false,
          fallback: SwimIqBrandedFallback(
            variant: SwimIqBrandedVariant.icon,
            width: size,
            height: size,
            borderRadius: 0,
          ),
        ),
      ),
    );
  }
}

/// Login / signup: full square app icon (icon.png) — contain, never zoom/crop.
class SwimIqLoginBrand extends StatelessWidget {
  const SwimIqLoginBrand({
    super.key,
    this.size = 200,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SwimIqBrandedImage(
            candidates: SwimIqBranding.loginIconCandidates,
            width: size - 24,
            height: size - 24,
            fit: BoxFit.contain,
            fallback: SwimIqPaintedMark(size: size - 24),
          ),
        ),
      ),
    );
  }
}

/// Login / splash: full square lockup at readable size (icon + wordmark on black).
class SwimIqFullLockup extends StatelessWidget {
  const SwimIqFullLockup({
    super.key,
    this.width = 280,
    this.borderRadius = 16,
    this.framed = false,
  });

  final double width;
  final double borderRadius;
  /// Black frame — use on white login/signup cards so the lockup always reads.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final image = SwimIqBrandedImage(
      candidates: SwimIqBranding.loginIconCandidates,
      width: width,
      height: width,
      fit: BoxFit.contain,
      borderRadius: framed ? 0 : borderRadius,
      fallback: _FullLockupFallback(width: width, borderRadius: borderRadius),
    );

    if (!framed) return image;

    return Container(
      width: width + 24,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 4),
        child: image,
      ),
    );
  }
}

class _FullLockupFallback extends StatelessWidget {
  const _FullLockupFallback({
    required this.width,
    required this.borderRadius,
  });

  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwimIqCompactMark(size: width * 0.5, borderRadius: borderRadius),
        const SizedBox(height: 12),
        SwimIqWordmark(fontSize: width * 0.13, light: true),
        const SizedBox(height: 6),
        Text(
          'Built in the Water. Driven by Possibility.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: width * 0.034,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Legacy alias — compact mark for tight slots.
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
    return SwimIqCompactMark(size: size, borderRadius: borderRadius);
  }
}

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
    return Center(
      child: SwimIqFullLockup(
        width: height * 1.4,
        borderRadius: borderRadius,
      ),
    );
  }
}

class SwimIqWordmark extends StatelessWidget {
  const SwimIqWordmark({
    super.key,
    this.fontSize = 22,
    this.showTm = true,
    this.light = true,
  });

  final double fontSize;
  final bool showTm;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final swimColor = light ? Colors.white : Colors.black;
    final iqColor = light ? AppColors.primary : AppColors.primaryDeep;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
              children: [
                TextSpan(text: 'Swim', style: TextStyle(color: swimColor)),
                TextSpan(text: 'IQ', style: TextStyle(color: iqColor)),
              ],
            ),
          ),
        ),
        if (showTm)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 1),
            child: Text(
              '™',
              style: TextStyle(
                color: iqColor,
                fontSize: fontSize * 0.42,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
