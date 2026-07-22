import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/next_cut_progress.dart';
import '../core/utils/swim_time.dart';

/// Compact progress toward the next USA motivational cut.
class NextCutProgressStrip extends StatelessWidget {
  const NextCutProgressStrip({
    super.key,
    required this.progress,
    this.compact = false,
  });

  final NextCutProgress progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (progress.atTopCut) {
      return _TopCutChip();
    }
    if (!progress.hasNextCut) {
      return const SizedBox.shrink();
    }

    final gap = progress.gapSeconds ?? 0;
    final targetTime = progress.nextCutTimeSeconds!;
    final barColor = progress.isClose ? AppColors.accent : AppColors.primary;

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.progressPercent / 100,
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                color: barColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            progress.gapLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: barColor,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Next: ${progress.nextCut} cut',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                progress.gapLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: barColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.progressPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: barColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'PB ${SwimTime.fromSeconds(progress.swimmerTimeSeconds)} · '
            'need ${SwimTime.fromSeconds(targetTime)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class NextCutSummaryCard extends StatelessWidget {
  const NextCutSummaryCard({
    super.key,
    required this.eventTitle,
    required this.progress,
  });

  final String eventTitle;
  final NextCutProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_circle, color: AppColors.primaryDeep, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Closest to next cut',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeep,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$eventTitle · ${progress.currentCutLabel} now',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            NextCutProgressStrip(progress: progress),
          ],
        ),
      ),
    );
  }
}

class _TopCutChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'AAAA — top USA cut',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeep,
          fontSize: 11,
        ),
      ),
    );
  }
}
