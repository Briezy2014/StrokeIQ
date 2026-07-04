import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/app_providers.dart';
import '../utils/personal_bests.dart';
import '../utils/swim_time.dart';
import '../utils/swimiq_score.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(swimmerDataProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load dashboard: $error')),
      data: (data) {
        if (data.raceLogs.isEmpty) {
          return const EmptyState(
            icon: Icons.dashboard_outlined,
            title: 'No swim sessions yet',
            message: 'Add a swim session to start building your dashboard.',
          );
        }

        final score = SwimIQScore.calculate(data.raceLogs, data.goals);
        final pbs = PersonalBests.fromRaceLogs(data.raceLogs);
        final times = data.raceLogs.map((log) => log.timeSeconds).toList();
        final bestTime = times.reduce((a, b) => a < b ? a : b);
        final avgTime = times.reduce((a, b) => a + b) / times.length;

        return RefreshIndicator(
          onRefresh: () async => refreshData(ref),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  MetricCard(
                    label: 'SwimIQ Score',
                    value: '$score',
                    icon: Icons.star_rounded,
                    highlight: true,
                  ),
                  MetricCard(
                    label: 'Total Sessions',
                    value: '${data.raceLogs.length}',
                    icon: Icons.fitness_center_rounded,
                  ),
                  MetricCard(
                    label: 'Personal Bests',
                    value: '${pbs.length}',
                    icon: Icons.emoji_events_outlined,
                  ),
                  MetricCard(
                    label: 'Active Goals',
                    value: '${data.goals.length}',
                    icon: Icons.flag_outlined,
                  ),
                  MetricCard(
                    label: 'Best Time',
                    value: SwimTime.fromSeconds(bestTime),
                    icon: Icons.timer_outlined,
                  ),
                  MetricCard(
                    label: 'Average Time',
                    value: SwimTime.fromSeconds(avgTime),
                    icon: Icons.speed_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Time Progress'),
              SizedBox(
                height: 220,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _TimeProgressChart(logs: data.raceLogs),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Recent Sessions'),
              ...data.raceLogs.take(10).map((log) => _SessionTile(log: log)),
            ],
          ),
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.log});

  final dynamic log;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: SwimIQTheme.lightSky,
          child: Text(
            log.course,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: SwimIQTheme.accentBlue,
            ),
          ),
        ),
        title: Text(
          log.event,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${log.date} · ${log.stroke}'),
        trailing: Text(
          SwimTime.fromSeconds(log.timeSeconds),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: SwimIQTheme.darkNavy,
              ),
        ),
      ),
    );
  }
}

class _TimeProgressChart extends StatelessWidget {
  const _TimeProgressChart({required this.logs});

  final List<dynamic> logs;

  @override
  Widget build(BuildContext context) {
    final strokeColors = {
      'Freestyle': SwimIQTheme.primaryBlue,
      'Backstroke': SwimIQTheme.accentBlue,
      'Breaststroke': const Color(0xFF00B894),
      'Butterfly': const Color(0xFFFF7675),
      'IM': const Color(0xFF6C5CE7),
      'Free': SwimIQTheme.primaryBlue,
    };

    final sorted = [...logs]
      ..sort((a, b) => a.date.compareTo(b.date));

    final strokes = sorted.map((l) => l.stroke.toString()).toSet().toList();
    final lineBars = <LineChartBarData>[];

    for (var i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final strokeLogs = sorted.where((l) => l.stroke == stroke).toList();
      final spots = <FlSpot>[];

      for (var j = 0; j < strokeLogs.length; j++) {
        spots.add(FlSpot(j.toDouble(), strokeLogs[j].timeSeconds));
      }

      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: strokeColors[stroke] ?? SwimIQTheme.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    if (lineBars.isEmpty) {
      return const Center(child: Text('Not enough data for chart'));
    }

    final allTimes = sorted.map((l) => l.timeSeconds).toList();
    final minY = allTimes.reduce((a, b) => a < b ? a : b) - 5;
    final maxY = allTimes.reduce((a, b) => a > b ? a : b) + 5;

    return LineChart(
      LineChartData(
        minY: minY > 0 ? minY : 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  SwimTime.fromSeconds(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBars,
      ),
    );
  }
}
