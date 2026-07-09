import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Gradient event card used on PB, meet results, and recruiting lists.
class SwimIqEventCard extends StatelessWidget {
  const SwimIqEventCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.highlight = false,
    this.trailingActions,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final bool highlight;
  final Widget? trailingActions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: highlight
              ? [
                  AppColors.primary.withValues(alpha: 0.18),
                  Colors.white,
                ]
              : [
                  AppColors.surfaceLight,
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.22),
          width: highlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailingActions ??
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trailing ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
              ],
            ),
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
