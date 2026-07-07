import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/swim_analytics.dart';
import '../data/models/swim_goal.dart';
import '../providers/swimmer_data_provider.dart';

class GoalsProgressChart extends StatelessWidget {
  const GoalsProgressChart({
    super.key,
    required this.goals,
    required this.data,
  });

  final List<SwimGoal> goals;
  final SwimmerData data;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    var achieved = 0;
    var onTrack = 0;
    var needsWork = 0;

    for (final goal in goals) {
      final best = SwimAnalytics.bestTimeForGoal(
        goal: goal,
        raceLogs: data.raceLogs,
      );
      final toGoal = SwimAnalytics.secondsToGoal(
        goal: goal,
        raceLogs: data.raceLogs,
      );
      if (best == null) {
        needsWork++;
      } else if (toGoal != null && toGoal <= 0) {
        achieved++;
      } else if (toGoal != null && toGoal <= 2) {
        onTrack++;
      } else {
        needsWork++;
      }
    }

    final sections = [
      _ChartSlice('Achieved', achieved, const Color(0xFF22C55E)),
      _ChartSlice('Close', onTrack, AppColors.primary),
      _ChartSlice('Building', needsWork, const Color(0xFFF97316)),
    ].where((slice) => slice.value > 0).toList();

    if (sections.isEmpty) {
      sections.add(_ChartSlice('Goals set', goals.length, AppColors.primary));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal tracker',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Where your goals stand today',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: sections
                            .map(
                              (slice) => PieChartSectionData(
                                value: slice.value.toDouble(),
                                color: slice.color,
                                title: '${slice.value}',
                                radius: 52,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final slice in sections)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: slice.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${slice.label} (${slice.value})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSlice {
  const _ChartSlice(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}
