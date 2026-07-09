import 'package:flutter/material.dart';

import '../core/models/subscription_plan.dart';
import '../core/theme/app_theme.dart';

/// Side-by-side feature comparison for membership plans.
class SubscriptionFeatureMatrix extends StatelessWidget {
  const SubscriptionFeatureMatrix({super.key});

  static const _rows = [
    _MatrixRow('Dashboard, training log & goals', basic: true, pro: true, elite: true),
    _MatrixRow('Weekly Progress Report', basic: true, pro: true, elite: true),
    _MatrixRow('In-app PB tracking & progress charts', basic: true, pro: true, elite: true),
    _MatrixRow('Swim streaks & milestone achievements', basic: true, pro: true, elite: true),
    _MatrixRow('Official PBs, meet results & USA standards', pro: true, elite: true),
    _MatrixRow('Athlete Passport / Recruiting Snapshot', pro: true, elite: true),
    _MatrixRow('AI Dryland Coach', pro: true, elite: true),
    _MatrixRow('Video Lab (upload & organize videos)', pro: true, elite: true),
    _MatrixRow('Video Lab AI Stroke Analysis (Gemini + MediaPipe)', elite: true),
    _MatrixRow('Race Intelligence', elite: true),
    _MatrixRow('AI Performance Reports & race strategy', elite: true),
    _MatrixRow('AI Recruiting Intelligence', elite: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare plans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.4),
                1: FlexColumnWidth(0.7),
                2: FlexColumnWidth(0.7),
                3: FlexColumnWidth(0.7),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.comingSoonBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    _headerCell('Feature'),
                    _headerCell('Basic', center: true),
                    _headerCell('Pro', center: true, highlight: true),
                    _headerCell('Elite', center: true),
                  ],
                ),
                ..._rows.map((row) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            row.label,
                            style: const TextStyle(height: 1.3),
                          ),
                        ),
                        _tierCell(row.basic),
                        _tierCell(row.pro),
                        _tierCell(row.elite),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${SubscriptionCatalog.planFor(SubscriptionTier.pro).name} is Most Popular — '
              'official times, recruiting tools & dryland coaching in one plan.',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, {bool center = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: highlight ? AppColors.primary : AppColors.textDark,
        ),
      ),
    );
  }

  Widget _tierCell(bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Icon(
        included ? Icons.check_circle : Icons.cancel_outlined,
        color: included ? Colors.green.shade600 : Colors.red.shade400,
        size: 22,
      ),
    );
  }
}

class _MatrixRow {
  const _MatrixRow(
    this.label, {
    this.basic = false,
    this.pro = false,
    this.elite = false,
  });

  final String label;
  final bool basic;
  final bool pro;
  final bool elite;
}
