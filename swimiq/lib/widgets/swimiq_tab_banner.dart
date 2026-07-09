import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'swimiq_branding.dart';
import 'swimiq_logo.dart';

/// Full-width brand strip below the app bar on every tab except Dashboard.
class SwimIqTabBanner extends StatelessWidget {
  const SwimIqTabBanner({
    super.key,
    required this.tabIndex,
  });

  final int tabIndex;

  static String? moduleLabelForTab(int index) {
    return switch (index) {
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
          height: 88,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SwimIqBrandedImage(
                candidates: SwimIqBranding.tabBannerCandidates,
                fit: BoxFit.cover,
                fallback: const DecoratedBox(
                  decoration: BoxDecoration(
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
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SwimIqCompactMark(size: 52, borderRadius: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const SwimIqWordmark(fontSize: 20),
                              _ModuleChip(label: module),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppConstants.brandTagline.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
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
