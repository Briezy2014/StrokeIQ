import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/race_log_providers.dart';
import '../../providers/standards_providers.dart';
import '../../widgets/standards/standard_progress_card.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/swimiq_app_bar.dart';

/// Training log with motivational standards on each session.
class TrainingLogScreen extends ConsumerWidget {
  const TrainingLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardsLoaded = ref.watch(standardsLoadedProvider);
    final logsAsync = ref.watch(raceLogsProvider);

    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Training Log'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!standardsLoaded) const StandardsEmptyState(),
          logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Could not load sessions: $error'),
            data: (logs) {
              if (logs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No training sessions yet. Each session will be compared '
                      'against the shared motivational standards repository.',
                    ),
                  ),
                );
              }

              return Column(
                children: logs.map((log) {
                  final comparisonAsync = ref.watch(
                    standardComparisonProvider((
                      event: log.event,
                      timeSeconds: log.timeSeconds,
                    )),
                  );

                  return comparisonAsync.when(
                    loading: () => const ListTile(
                      title: Text('Loading standards...'),
                    ),
                    error: (error, _) => ListTile(
                      title: Text(log.event),
                      subtitle: Text('Standards error: $error'),
                    ),
                    data: (comparison) {
                      if (comparison == null) {
                        return ListTile(
                          title: Text(log.event),
                          subtitle: const Text('No matching standard'),
                        );
                      }
                      return StandardProgressCard(
                        title: '${log.event} · ${log.date.toLocal().toString().split(' ').first}',
                        comparison: comparison,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/home/personal-bests'),
            child: const Text('View Personal Bests'),
          ),
        ],
      ),
    );
  }
}
