import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'swimiq_branded_fallback.dart';
import 'swimiq_branding.dart';

/// Small slot: square swimmer icon only — never stretches a wide lockup.
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
        clipBehavior: Clip.hardEdge,
        child: ColoredBox(
          color: AppColors.primaryDeep,
          child: SwimIqBrandedImage(
            candidates: SwimIqBranding.compactCandidates,
            width: size,
            height: size,
            fit: BoxFit.contain,
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

/// Login / splash: full square lockup at a fixed, readable size.
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
    return Center(
      child: SwimIqBrandedImage(
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

/// Compact branding row — never full-width stretched PNGs.
class SwimIqHeroBanner extends StatelessWidget {
  const SwimIqHeroBanner({
    super.key,
    this.height = 140,
    this.borderRadius = 20,
    this.light = true,
    this.centered = true,
  });

  final double height;
  final double borderRadius;
  final bool light;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final markSize = height.clamp(40.0, 72.0);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwimIqCompactMark(size: markSize, borderRadius: borderRadius * 0.6),
        const SizedBox(width: 12),
        Flexible(
          child: SwimIqWordmark(
            fontSize: markSize * 0.42,
            light: light,
          ),
        ),
      ],
    );

    if (!centered) return row;
    return Center(child: row);
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
