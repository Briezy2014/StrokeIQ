import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LimitationsPanel extends StatelessWidget {
  const LimitationsPanel({
    super.key,
    required this.limitations,
    this.title = 'Limitations',
  });

  final List<String> limitations;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (limitations.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.comingSoonBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.comingSoonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 8),
          ...limitations.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
