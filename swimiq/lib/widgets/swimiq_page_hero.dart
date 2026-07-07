import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'swimiq_logo.dart';

/// Gradient hero block for tab screens — logo + title + optional quote/stats.
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050505),
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SwimIqHeroBanner(height: 52, borderRadius: 12),
          const SizedBox(height: 14),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              fontSize: 13,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
          if (quote != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                quote!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats
                  .map(
                    (stat) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        stat.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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
