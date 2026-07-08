import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'swimiq_branded_fallback.dart';
import 'swimiq_branding.dart';

/// Square SwimIQ icon — padded so the full logo stays readable in every slot.
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
    final pad = (size * 0.1).clamp(4.0, 12.0);
    final inner = size - pad * 2;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: AppColors.primaryDeep.withValues(alpha: 0.08),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: SwimIqBrandedImage(
              candidates: SwimIqBranding.iconCandidates,
              width: inner,
              height: inner,
              fit: BoxFit.contain,
              borderRadius: 0,
              fallback: SwimIqBrandedFallback(
                variant: SwimIqBrandedVariant.icon,
                width: inner,
                height: inner,
                borderRadius: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered icon for login / splash — no wide banner asset.
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
    final iconSize = (height * 0.85).clamp(72.0, 160.0);
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
