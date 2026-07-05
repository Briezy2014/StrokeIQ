import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/swimiq_theme.dart';
import '../../../domain/models/race_log.dart';
import '../../../domain/utils/swim_time_utils.dart';

class TimeProgressChart extends StatelessWidget {
  const TimeProgressChart({super.key, required this.raceLogs});

  final List<RaceLog> raceLogs;

  @override
  Widget build(BuildContext context) {
    final chartLogs = raceLogs
        .where((log) => log.date != null && log.timeSeconds > 0)
        .toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    if (chartLogs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Add swim sessions to see your time progress chart.'),
        ),
      );
    }

    final strokes = chartLogs.map((log) => log.stroke).toSet().toList();
    final strokeColors = {
      for (var i = 0; i < strokes.length; i++)
        strokes[i]: _palette[i % _palette.length],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: _minY(chartLogs),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            SwimTimeUtils.secondsToSwimTime(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: chartLogs.length > 4 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= chartLogs.length) {
                            return const SizedBox.shrink();
                          }
                          final date = chartLogs[index].date!;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat.Md().format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: strokes.map((stroke) {
                    final strokeLogs = chartLogs
                        .where((log) => log.stroke == stroke)
                        .toList();

                    return LineChartBarData(
                      isCurved: true,
                      color: strokeColors[stroke],
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      spots: [
                        for (final log in strokeLogs)
                          FlSpot(
                            chartLogs.indexOf(log).toDouble(),
                            log.timeSeconds,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                for (final stroke in strokes)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: strokeColors[stroke],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(stroke, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _minY(List<RaceLog> logs) {
    final minTime = logs.map((log) => log.timeSeconds).reduce((a, b) => a < b ? a : b);
    return (minTime - 2).clamp(0, double.infinity).toDouble();
  }

  static const _palette = [
    SwimIQColors.primary,
    SwimIQColors.primaryDark,
    SwimIQColors.accent,
    Colors.deepPurple,
    Colors.teal,
  ];
}
