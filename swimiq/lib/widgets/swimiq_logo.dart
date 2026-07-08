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
        child: ColoredBox(
          color: AppColors.primaryDeep,
          child: SwimIqBrandedImage(
            candidates: SwimIqBranding.compactCandidates,
            width: size,
            height: size,
            fit: BoxFit.cover,
            zoomToMark: true,
            fallback: SwimIqBrandedFallback(
              variant: SwimIqBrandedVariant.icon,
              width: size,
              height: size,
              borderRadius: 0,
            ),
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
  });

  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SwimIqBrandedImage(
      candidates: SwimIqBranding.fullLockupCandidates,
      width: width,
      height: width,
      fit: BoxFit.contain,
      borderRadius: borderRadius,
      fallback: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwimIqCompactMark(size: width * 0.45, borderRadius: borderRadius),
          const SizedBox(height: 12),
          SwimIqWordmark(fontSize: width * 0.12, light: false),
        ],
      ),
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
    final swimColor = light ? Colors.white : AppColors.textDark;
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
