import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dashboard_insights.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(appViewModeProvider);

    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final logs = data.raceLogs;
        final snapshot = data.passportSnapshot(swimmer);
        final subtitle = dashboardSubtitleForMode(
          mode: viewMode,
          displayName: data.displayName(swimmer),
          swimIqExplanation: snapshot.swimIqExplanation,
        );

        if (logs.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SwimIqScreenHeader(
                title: 'Swimmer Dashboard',
                subtitle: subtitle,
              ),
              const SizedBox(height: 16),
              DashboardInsightCards(data: data, swimmer: swimmer),
              const SizedBox(height: 16),
              const EmptyStateMessage(
                message:
                    'No swim sessions yet. Add a swim session to start building the dashboard.',
              ),
            ],
          );
        }

        final personalBests = data.personalBests;
        final dateFormat = DateFormat.yMMMd();

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqScreenHeader(
              title: 'Swimmer Dashboard',
              subtitle: subtitle,
            ),
            const SizedBox(height: 16),
            DashboardInsightCards(data: data, swimmer: swimmer),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                SwimIqMetricCard(
                  label: 'SwimIQ Score',
                  value: '${data.swimIqScore}',
                ),
                SwimIqMetricCard(
                  label: 'Total Sessions',
                  value: '${logs.length}',
                ),
                SwimIqMetricCard(
                  label: 'Personal Bests',
                  value: '${personalBests.length}',
                ),
                SwimIqMetricCard(
                  label: 'Active Goals',
                  value: '${data.goals.length}',
                ),
                SwimIqMetricCard(
                  label: 'Meet Results',
                  value: '${data.meetResults.length}',
                ),
                SwimIqMetricCard(
                  label: 'Video Analyses',
                  value: '${data.userFacingVideoAnalyses.length}',
                ),
                SwimIqMetricCard(
                  label: 'Best Time',
                  value: SwimAnalytics.bestTime(logs),
                ),
                SwimIqMetricCard(
                  label: 'Highest Motivational Cut',
                  value: snapshot.highestCut,
                ),
                SwimIqMetricCard(
                  label: 'Standards Version',
                  value: data.motivationalStandards.versionId,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Session History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...logs.map(
              (log) {
                final cut = MotivationalCut.labelForSwim(
                  catalog: data.motivationalStandards,
                  profile: data.profile,
                  stroke: log.stroke,
                  distance: log.distance,
                  course: log.course,
                  timeSeconds: log.timeSeconds,
                );
                return SwimIqEventListTile(
                  title: '${log.distance} ${log.stroke} · ${log.course}',
                  subtitle:
                      '${dateFormat.format(log.date)} · ${log.event} · $cut cut',
                  trailing: SwimTime.fromSeconds(log.timeSeconds),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Time Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TimeProgressChart(logs: logs),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeProgressChart extends StatelessWidget {
  const _TimeProgressChart({required this.logs});

  final List<RaceLog> logs;

  static const _strokeColors = {
    'Freestyle': Color(0xFF009CFF),
    'Backstroke': Color(0xFF38B6FF),
    'Breaststroke': Color(0xFF0077C8),
    'Butterfly': Color(0xFF0B5CAD),
    'IM': Color(0xFF0B2D4D),
    'Free': Color(0xFF009CFF),
  };

  @override
  Widget build(BuildContext context) {
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final strokes = sorted.map((log) => log.stroke).toSet().toList();

    final lineBars = <LineChartBarData>[];
    for (final stroke in strokes) {
      final strokeLogs = sorted.where((log) => log.stroke == stroke).toList();
      final spots = <FlSpot>[];
      for (var i = 0; i < strokeLogs.length; i++) {
        spots.add(FlSpot(i.toDouble(), strokeLogs[i].timeSeconds));
      }
      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _strokeColors[stroke] ?? Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      );
    }

    if (lineBars.isEmpty) {
      return const Center(child: Text('Not enough data for chart.'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sorted.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.Md().format(sorted[index].date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                SwimTime.fromSeconds(value),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBars,
      ),
    );
  }
}
