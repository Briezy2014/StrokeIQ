import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/swimiq_theme.dart';
import '../../data/repositories/race_log_repository.dart';
import '../../domain/utils/personal_best_utils.dart';
import '../../domain/utils/swim_time_utils.dart';
import '../../router/app_router.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceLogsAsync = ref.watch(raceLogsProvider);

    return Scaffold(
      body: raceLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load training log: $error'),
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No swim sessions yet. Tap + to add your first training session.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final entries = logs.map((log) => log.toEntry()).toList();
          final bests = PersonalBestUtils.bestByEvent(entries);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(raceLogsProvider);
              await ref.read(raceLogsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                final isPb = bests.any(
                      (best) =>
                          best.stroke == log.stroke &&
                          best.distance == log.distance &&
                          best.course == log.course &&
                          best.timeSeconds == log.timeSeconds,
                    );

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isPb ? SwimIQColors.surfaceTint : Colors.grey.shade100,
                      child: Icon(
                        isPb ? Icons.emoji_events : Icons.pool,
                        color: isPb
                            ? SwimIQColors.primaryDark
                            : SwimIQColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      log.event.isNotEmpty ? log.event : '${log.distance} ${log.stroke}',
                    ),
                    subtitle: Text(
                      [
                        if (log.date != null) DateFormat.yMMMd().format(log.date!),
                        log.course,
                        if (log.notes != null && log.notes!.isNotEmpty) log.notes,
                      ].whereType<String>().join(' · '),
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
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoute.trainingAdd.path),
        icon: const Icon(Icons.add),
        label: const Text('Add Session'),
      ),
    );
  }
}
