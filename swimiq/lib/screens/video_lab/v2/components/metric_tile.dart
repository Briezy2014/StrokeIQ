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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: showAsFact ? AppColors.primaryDark : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }
}
