import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/swimiq_theme.dart';
import '../../domain/utils/swim_time_utils.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/race_log_repository.dart';
import '../../providers/dashboard_providers.dart';
import 'widgets/metric_card.dart';
import 'widgets/time_progress_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load dashboard: $error'),
        ),
      ),
      data: (summary) {
        if (summary.raceLogs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No swim sessions yet. Add a training session to start building your dashboard.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(raceLogsProvider);
            ref.invalidate(goalsProvider);
            ref.invalidate(dashboardSummaryProvider);
            await ref.read(dashboardSummaryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MetricCard(
                label: 'SwimIQ Score',
                value: '${summary.swimIqScore}',
                highlight: true,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  MetricCard(
                    label: 'Total Sessions',
                    value: '${summary.totalSessions}',
                  ),
                  MetricCard(
                    label: 'Personal Bests',
                    value: '${summary.personalBests}',
                  ),
                  MetricCard(
                    label: 'Active Goals',
                    value: '${summary.activeGoals}',
                  ),
                  MetricCard(
                    label: 'Best Time',
                    value: summary.bestTime,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MetricCard(
                label: 'Average Time',
                value: summary.averageTime,
              ),
              const SizedBox(height: 16),
              TimeProgressChart(raceLogs: summary.raceLogs),
              const SizedBox(height: 16),
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...summary.raceLogs.take(8).map((log) {
                return Card(
                  child: ListTile(
                    title: Text(log.event.isNotEmpty ? log.event : '${log.distance} ${log.stroke}'),
                    subtitle: Text(
                      [
                        if (log.date != null) DateFormat.yMMMd().format(log.date!),
                        log.course,
                      ].join(' · '),
                    ),
                    trailing: Text(
                      SwimTimeUtils.secondsToSwimTime(log.timeSeconds),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: SwimIQColors.primaryDark,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
