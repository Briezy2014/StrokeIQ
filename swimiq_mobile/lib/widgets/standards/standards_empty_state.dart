import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Shown when the motivational standards table has not been imported yet.
class StandardsEmptyState extends StatelessWidget {
  const StandardsEmptyState({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Standards not loaded',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Import the official USA Swimming Age Group Motivational '
              'Standards PDF to populate the shared standards database.',
            ),
            const SizedBox(height: 8),
            Text(
              'Version: ${AppConstants.defaultStandardsVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'python scripts/import_motivational_standards.py --pdf path/to/standards.pdf',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
