import 'package:flutter/material.dart';

import '../../core/swim_time_utils.dart';
import '../../core/theme.dart';
import '../../models/standard_level.dart';
import '../../services/standards_analytics.dart';

class StandardProgressCard extends StatelessWidget {
  const StandardProgressCard({
    super.key,
    required this.comparison,
    this.title,
  });

  final StandardComparison comparison;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final progress = comparison.percentProgress ?? 0;
    final nextGap = comparison.timeToNextStandard;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Text('Event: ${comparison.standard.event}'),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Your time',
              value: SwimTimeUtils.secondsToSwimTime(comparison.swimTimeSeconds),
            ),
            _InfoRow(
              label: 'Current standard',
              value: comparison.currentLevelLabel,
            ),
            if (comparison.nextLevel != null) ...[
              _InfoRow(
                label: 'Next standard',
                value: comparison.nextLevel!.label,
              ),
              if (nextGap != null)
                _InfoRow(
                  label: 'Time to next',
                  value: nextGap <= 0
                      ? 'Inside cutoff'
                      : '${nextGap.toStringAsFixed(2)} sec',
                ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 10,
                  backgroundColor: SwimIqColors.surface,
                  color: SwimIqColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text('${progress.toStringAsFixed(0)}% toward ${comparison.nextLevel!.label}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class StandardLevelPicker extends StatelessWidget {
  const StandardLevelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final StandardLevel selected;
  final ValueChanged<StandardLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: StandardLevel.values.map((level) {
        final isSelected = level == selected;
        return ChoiceChip(
          label: Text(level.label),
          selected: isSelected,
          onSelected: (_) => onChanged(level),
        );
      }).toList(),
    );
  }
}
