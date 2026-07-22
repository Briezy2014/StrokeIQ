import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/goal_progress_analytics.dart';
import '../core/utils/swim_time.dart';
import '../data/models/swim_goal.dart';
import '../providers/swimmer_data_provider.dart';

class GoalsCutsBanner extends StatelessWidget {
  const GoalsCutsBanner({super.key, required this.snapshots});

  final List<GoalProgressSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final earned = snapshots
        .where((s) => s.bestTime != null && s.currentCut != '—')
        .map(
          (s) => _CutChipData(
            event: s.goal.event,
            cut: s.currentCut,
            course: s.goal.course,
          ),
        )
        .toList();

    if (earned.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Log swims on the Log tab or official meet times to see USA cuts '
            'light up here.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryDeep.withValues(alpha: 0.92),
              AppColors.primary,
              AppColors.accent.withValues(alpha: 0.85),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuts on your radar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: earned
                  .map((chip) => _CutBadge(chip: chip))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CutChipData {
  const _CutChipData({
    required this.event,
    required this.cut,
    required this.course,
  });

  final String event;
  final String cut;
  final String course;
}

class _CutBadge extends StatelessWidget {
  const _CutBadge({required this.chip});

  final _CutChipData chip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chip.cut,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${chip.event} · ${chip.course}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.snapshot,
    required this.onDelete,
  });

  final GoalProgressSnapshot snapshot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final goal = snapshot.goal;
    final dateFormat = DateFormat.yMMMd();
    final statusColor = switch (snapshot.status) {
      GoalProgressStatus.achieved => const Color(0xFF22C55E),
      GoalProgressStatus.close => AppColors.primary,
      GoalProgressStatus.building => const Color(0xFFF97316),
      GoalProgressStatus.noData => Colors.grey,
    };
    final statusLabel = switch (snapshot.status) {
      GoalProgressStatus.achieved => 'Goal hit!',
      GoalProgressStatus.close => 'Almost there',
      GoalProgressStatus.building => 'Building',
      GoalProgressStatus.noData => 'Need a time',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${goal.event} (${goal.course})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target ${SwimTime.fromSeconds(goal.goalTime)} · '
                        'Due ${dateFormat.format(goal.targetDate)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatPill(
                  label: 'Current cut',
                  value: snapshot.currentCut,
                  color: AppColors.primaryDeep,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'Goal cut',
                  value: snapshot.goalCut,
                  color: AppColors.accent,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: snapshot.progressPercent / 100,
                backgroundColor: Colors.grey.shade200,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _progressCaption(snapshot),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (snapshot.history.length >= 2) ...[
              const SizedBox(height: 16),
              Text(
                'Progress chart',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: _GoalMiniLineChart(snapshot: snapshot),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _progressCaption(GoalProgressSnapshot snapshot) {
    if (snapshot.bestTime == null) {
      return 'No times logged yet — add a swim on Log or an official meet result.';
    }
    if (snapshot.isAchieved) {
      return 'PB ${SwimTime.fromSeconds(snapshot.bestTime!)} — goal achieved!';
    }
    final toGo = snapshot.secondsToGoal!;
    return 'PB ${SwimTime.fromSeconds(snapshot.bestTime!)} · '
        '${SwimTime.fromSeconds(toGo)} to goal · '
        '${snapshot.progressPercent.round()}% of the way';
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMiniLineChart extends StatelessWidget {
  const _GoalMiniLineChart({required this.snapshot});

  final GoalProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final history = snapshot.history;
    final goalY = snapshot.goal.goalTime;
    final times = history.map((p) => p.timeSeconds).toList()..add(goalY);
    final minY = times.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = times.reduce((a, b) => a > b ? a : b) + 1;

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.timeSeconds);
    }).toList();

    final goalLine = history.length <= 1
        ? null
        : LineChartBarData(
            spots: [
              FlSpot(0, goalY),
              FlSpot((history.length - 1).toDouble(), goalY),
            ],
            isCurved: false,
            color: const Color(0xFF22C55E).withValues(alpha: 0.7),
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          );

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                SwimTime.fromSeconds(value),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DateFormat.Md().format(history[index].date),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: history[index].sourceLabel == 'Meet'
                    ? AppColors.accent
                    : AppColors.primaryDeep,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          if (goalLine != null) goalLine,
        ],
      ),
    );
  }
}

List<GoalProgressSnapshot> buildGoalSnapshots(SwimmerData data) {
  return GoalProgressAnalytics.allSnapshots(
    goals: data.goals,
    raceLogs: data.raceLogs,
    meetResults: data.meetResults,
    catalog: data.motivationalStandards,
    profile: data.profile,
  );
}
