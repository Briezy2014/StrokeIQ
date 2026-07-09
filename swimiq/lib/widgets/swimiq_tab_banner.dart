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

  static const tabModuleLabels = <int, String>{
    HomeTab.dashboard: 'Dashboard',
    HomeTab.personalBests: 'PBs',
    HomeTab.trainingLog: 'Log',
    HomeTab.goals: 'Goals',
    HomeTab.videoLab: 'Video Lab',
    HomeTab.passport: 'Passport',
  };

  static String? moduleLabelForTab(int index) => tabModuleLabels[index];

  static bool hasBannerForTab(int index) => tabModuleLabels.containsKey(index);

  @override
  Widget build(BuildContext context) {
    final module = moduleLabelForTab(tabIndex);
    if (module == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: 116,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF020812)),
            SwimIqBrandedImage(
              candidates: SwimIqBranding.tabBannerCandidates,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              fallback: const _BannerMarkFallback(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                  child: Text(
                    AppConstants.brandTagline,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: _ModuleChip(label: module),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered mark when banner.png is missing.
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
            SwimIqBranding.markAsset,
            ...SwimIqBranding.markCandidates,
          ],
          height: 88,
          fit: BoxFit.contain,
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
