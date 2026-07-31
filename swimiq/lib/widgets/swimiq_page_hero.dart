import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'swimiq_logo.dart';

enum SwimIqPageHeroTone {
  /// Default: dark title on white page background.
  light,

  /// Blue banner with white title/subtitle (readable on primaryDeep).
  onPrimary,
}

/// Tab header: title + optional stats (brand banner is above on [HomeScreen]).
class SwimIqPageHero extends StatelessWidget {
  const SwimIqPageHero({
    super.key,
    required this.title,
    this.subtitle,
    this.stats = const [],
    this.showMark = false,
    this.tone = SwimIqPageHeroTone.light,
  });

  final String title;
  final String? subtitle;
  final List<SwimIqHeroStat> stats;
  final bool showMark;
  final SwimIqPageHeroTone tone;

  bool get _onPrimary => tone == SwimIqPageHeroTone.onPrimary;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: _onPrimary ? Colors.white : AppColors.primaryDeep,
          height: 1.15,
          fontSize: 22,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _onPrimary
              ? Colors.white.withValues(alpha: 0.92)
              : AppColors.textDark.withValues(alpha: 0.72),
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showMark) ...[
          const SwimIqCompactMark(size: 56, borderRadius: 14),
          const SizedBox(height: 12),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle,
          ),
        ],
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: stats
                .map(
                  (stat) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _onPrimary
                          ? Colors.white.withValues(alpha: 0.16)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _onPrimary
                            ? Colors.white.withValues(alpha: 0.35)
                            : AppColors.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      stat.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _onPrimary ? Colors.white : AppColors.primaryDeep,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );

    if (!_onPrimary) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: column,
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      child: column,
    );
  }
}

class SwimIqHeroStat {
  const SwimIqHeroStat(this.label);
  final String label;
}
