import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'swimiq_branding.dart';

/// Login / signup header: one square logo + tagline (no duplicate wordmarks).
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
          child: SwimIqLogo(size: logoSize, borderRadius: logoSize * 0.2),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.tagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B2D4D),
                height: 1.4,
              ),
        ),
        if (title != null) ...[
          const SizedBox(height: 16),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ],
    );
  }
}

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
      fallback: Icon(Icons.pool, size: size * 0.7, color: Colors.white),
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
    return SwimIqBrandedImage(
      candidates: SwimIqBranding.heroCandidates,
      width: double.infinity,
      height: height,
      fit: BoxFit.contain,
      borderRadius: borderRadius,
      fallback: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SwimIqWordmark(fontSize: 32),
          const SizedBox(height: 8),
          Text(
            AppConstants.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B2D4D),
            ),
          ),
        ],
      ),
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
