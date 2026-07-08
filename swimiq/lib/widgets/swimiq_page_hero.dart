import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'swimiq_logo.dart';

/// Tab header: centered square icon + title (no wide banner, no stretched lockup).
class SwimIqPageHero extends StatelessWidget {
  const SwimIqPageHero({
    super.key,
    required this.title,
    this.subtitle,
    this.quote,
    this.stats = const [],
  });

  final String title;
  final String? subtitle;
  final String? quote;
  final List<SwimIqHeroStat> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SwimIqCompactMark(size: 56, borderRadius: 14),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                  height: 1.15,
                ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.72),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (quote != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                quote!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
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
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        stat.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryDeep,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class SwimIqHeroStat {
  const SwimIqHeroStat(this.label);
  final String label;
}
