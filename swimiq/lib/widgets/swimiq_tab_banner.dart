import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/swimiq_quotes.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'swimiq_branding.dart';
import 'swimiq_branded_fallback.dart';

/// Compact brand strip: motivational quote in blue bar + scaled banner mark.
class SwimIqTabBanner extends StatelessWidget {
  const SwimIqTabBanner({
    super.key,
    required this.tabIndex,
    required this.swimmer,
  });

  final int tabIndex;
  final String swimmer;

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

  static List<String> quotePoolForTab(int tabIndex) => switch (tabIndex) {
        HomeTab.dashboard => SwimIqQuotes.dashboard,
        HomeTab.personalBests => SwimIqQuotes.personalBests,
        HomeTab.trainingLog => SwimIqQuotes.trainingLog,
        HomeTab.goals => SwimIqQuotes.goals,
        HomeTab.videoLab => SwimIqQuotes.videoLab,
        HomeTab.passport => SwimIqQuotes.recruiting,
        _ => const [],
      };

  static String quoteForTab(String swimmer, int tabIndex) {
    return SwimIqQuotes.pickFor(swimmer, quotePoolForTab(tabIndex));
  }

  @override
  Widget build(BuildContext context) {
    final module = moduleLabelForTab(tabIndex);
    if (module == null) return const SizedBox.shrink();

    final quote = quoteForTab(swimmer, tabIndex);
    final quoteText =
        quote.isNotEmpty ? quote : AppConstants.brandTagline;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuoteStrip(text: quoteText),
        _CompactBannerStrip(module: module),
      ],
    );
  }
}

class _QuoteStrip extends StatelessWidget {
  const _QuoteStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.25,
                fontSize: 13.5,
              ),
        ),
      ),
    );
  }
}

class _CompactBannerStrip extends StatelessWidget {
  const _CompactBannerStrip({required this.module});

  final String module;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF020812)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Center(
              child: SwimIqBrandedImage(
                candidates: SwimIqBranding.tabBannerCandidates,
                height: 44,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                fallback: const _BannerMarkFallback(),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 10,
            child: _ModuleChip(label: module),
          ),
        ],
      ),
    );
  }
}

/// Centered mark when banner.png is missing.
class _BannerMarkFallback extends StatelessWidget {
  const _BannerMarkFallback();

  @override
  Widget build(BuildContext context) {
    return SwimIqBrandedImage(
      candidates: [
        SwimIqBranding.markAsset,
        ...SwimIqBranding.markCandidates,
      ],
      height: 40,
      fit: BoxFit.contain,
      fallback: const SwimIqPaintedMark(size: 36),
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
              fontSize: 11.5,
            ),
      ),
    );
  }
}
