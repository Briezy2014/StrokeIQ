import 'package:flutter/material.dart';

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
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF020812)),
              SwimIqBrandedImage(
                candidates: SwimIqBranding.tabBannerCandidates,
                fit: BoxFit.fitWidth,
                alignment: Alignment.center,
                fallback: const _BannerMarkFallback(),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: _ModuleChip(label: module),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered mark/icon when banner.png is missing.
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
          candidates: SwimIqBranding.tabBannerCandidates,
          height: 88,
          fit: BoxFit.fitHeight,
          fallback: const SwimIqPaintedMark(size: 72),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
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
