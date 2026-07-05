import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.data});

  final SwimmerData data;

  @override
  Widget build(BuildContext context) {
    final logs = data.raceLogs;

    if (logs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EmptyStateMessage(
            message:
                'No swim sessions yet. Add a swim session to start building the dashboard.',
          ),
        ],
      );
    }

    final score = SwimAnalytics.calculateSwimIqScore(
      raceLogs: logs,
      goals: data.goals,
    );
    final personalBests = SwimAnalytics.personalBests(logs);
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Swimmer Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            MetricCard(label: 'SwimIQ Score', value: '$score'),
            MetricCard(label: 'Total Sessions', value: '${logs.length}'),
            MetricCard(
              label: 'Personal Bests',
              value: '${personalBests.length}',
            ),
            MetricCard(label: 'Active Goals', value: '${data.goals.length}'),
            MetricCard(
              label: 'Fastest Session',
              value: SwimAnalytics.bestTime(logs),
            ),
            MetricCard(
              label: 'Avg Session',
              value: SwimAnalytics.averageTime(logs),
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
        ...logs.map((log) => _SessionTile(log: log, dateFormat: dateFormat)),
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
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.log, required this.dateFormat});

  final RaceLog log;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${log.distance} ${log.stroke} · ${log.course}'),
        subtitle: Text(
          '${dateFormat.format(log.date)} · ${log.event}',
        ),
        trailing: Text(
          SwimTime.fromSeconds(log.timeSeconds),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
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
