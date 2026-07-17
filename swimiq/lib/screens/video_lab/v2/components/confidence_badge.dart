import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.confidenceLabel,
    this.isLowConfidence = false,
    this.isUnavailable = false,
  });

  final String confidenceLabel;
  final bool isLowConfidence;
  final bool isUnavailable;

  @override
  Widget build(BuildContext context) {
    final label = isUnavailable
        ? 'unavailable'
        : confidenceLabel.trim().isEmpty
            ? 'unknown'
            : confidenceLabel.trim().toLowerCase();

    final color = switch (label) {
      'high' => Colors.green.shade700,
      'moderate' => Colors.orange.shade800,
      'low' => Colors.deepOrange.shade700,
      'unavailable' => Colors.grey.shade700,
      _ => AppColors.primaryDark,
    };

    final text = isUnavailable
        ? 'Unavailable'
        : isLowConfidence
            ? 'Low confidence'
            : '${label[0].toUpperCase()}${label.substring(1)} confidence';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
