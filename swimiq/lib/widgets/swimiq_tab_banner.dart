import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../providers/app_providers.dart';
import 'swimiq_branding.dart';
import 'swimiq_branded_fallback.dart';

/// Full-width brand strip below the app bar on every tab (including Dashboard).
class SwimIqTabBanner extends StatelessWidget {
  const SwimIqTabBanner({
    super.key,
    required this.tabIndex,
  });

  final int tabIndex;

  static String? moduleLabelForTab(int index) {
    return switch (index) {
      HomeTab.dashboard => 'Dashboard',
      HomeTab.personalBests => 'Personal Bests',
      HomeTab.trainingLog => 'Training Log',
      HomeTab.goals => 'Goals',
      HomeTab.videoLab => 'Video Lab',
      HomeTab.passport => 'Recruiting Passport',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final module = moduleLabelForTab(tabIndex);
    if (module == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 104,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SwimIqBrandedImage(
                candidates: SwimIqBranding.tabBannerCandidates,
                fit: BoxFit.cover,
                fallback: const _BannerMarkFallback(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppConstants.brandTagline.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ModuleChip(label: module),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// When banner.png is missing — centered mark/icon, not a tiny corner glyph.
class _BannerMarkFallback extends StatelessWidget {
  const _BannerMarkFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF020812),
            Color(0xFF0B2D4D),
            Color(0xFF0B5CAD),
            Color(0xFF009CFF),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Center(
        child: SwimIqBrandedImage(
          candidates: [
            ...SwimIqBranding.markCandidates,
            SwimIqBranding.iconAsset,
          ],
          height: 88,
          width: 88,
          fit: BoxFit.contain,
          fallback: const SwimIqPaintedMark(size: 88),
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
