import 'package:flutter/material.dart';

import '../../../core/theme/swimiq_theme.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? SwimIQColors.surfaceTint : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: SwimIQColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: highlight ? SwimIQColors.primaryDark : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
