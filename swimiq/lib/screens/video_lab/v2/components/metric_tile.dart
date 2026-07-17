import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/video_engine_v2/video_engine_v2_models.dart';
import 'confidence_badge.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.metric});

  final AnalysisMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAsFact = !metric.isUnavailable && !metric.isLowConfidence;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.displayName.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                ConfidenceBadge(
                  confidenceLabel: metric.confidenceLabel,
                  isLowConfidence: metric.isLowConfidence,
                  isUnavailable: metric.isUnavailable,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              metric.displayWithUnit,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: showAsFact ? AppColors.textDark : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Classification: ${metric.classification}',
              style: theme.textTheme.bodySmall,
            ),
            if (metric.isUnavailable &&
                metric.unavailableReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                metric.unavailableReason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (metric.isLowConfidence && !metric.isUnavailable) ...[
              const SizedBox(height: 6),
              Text(
                'Low confidence — treat as an estimate, not a fact.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.deepOrange.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
