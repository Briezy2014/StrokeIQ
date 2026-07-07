import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Gradient event card used on PB, meet results, and recruiting lists.
class SwimIqEventCard extends StatelessWidget {
  const SwimIqEventCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.highlight = false,
    this.trailingActions,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final bool highlight;
  final Widget? trailingActions;

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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        isThreeLine: subtitle.contains('\n'),
        trailing: trailingActions ??
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trailing,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
      ),
    );
  }
}
