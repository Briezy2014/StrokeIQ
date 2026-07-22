import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../data/models/race_log.dart';
import '../data/models/swim_goal.dart';

/// Weekly summary included with Basic and above.
class WeeklyProgressReportCard extends StatelessWidget {
  const WeeklyProgressReportCard({
    super.key,
    required this.raceLogs,
    required this.goals,
  });

  final List<RaceLog> raceLogs;
  final List<SwimGoal> goals;

  static int _streakDays(List<RaceLog> raceLogs) {
    if (raceLogs.isEmpty) return 0;
    final days = raceLogs
        .map((log) => DateTime(log.date.year, log.date.month, log.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    var streak = 1;
    for (var i = 0; i < days.length - 1; i++) {
      if (days[i].difference(days[i + 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekLogs = raceLogs.where((log) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      return !day.isBefore(start);
    }).toList();

    final streak = _streakDays(raceLogs);
    final weekLabel = DateFormat.MMMd().format(weekStart);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Weekly Progress Report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Week of $weekLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: 'Sessions', value: '${weekLogs.length}'),
                _StatChip(label: 'Active goals', value: '${goals.length}'),
                _StatChip(
                  label: 'Training days',
                  value: '${weekLogs.map((l) => l.date.day).toSet().length}',
                ),
                if (streak >= 3)
                  _StatChip(label: 'Swim streak', value: '$streak days'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              weekLogs.isEmpty
                  ? 'Log a session this week to start your progress report.'
                  : streak >= 7
                      ? 'Week warrior! Seven-day streak — keep the momentum going.'
                      : 'Keep logging — your charts and milestones update automatically.',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.comingSoonBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.comingSoonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
