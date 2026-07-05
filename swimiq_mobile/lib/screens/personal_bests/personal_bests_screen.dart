import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/swim_time_utils.dart';
import '../../providers/race_log_providers.dart';
import '../../providers/standards_providers.dart';
import '../../widgets/standards/standard_progress_card.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/swimiq_app_bar.dart';

/// Personal bests compared against motivational standards.
class PersonalBestsScreen extends ConsumerWidget {
  const PersonalBestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardsLoaded = ref.watch(standardsLoadedProvider);
    final personalBestsAsync = ref.watch(personalBestsProvider);

    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Personal Bests'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!standardsLoaded) const StandardsEmptyState(),
          personalBestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Could not load personal bests: $error'),
            data: (personalBests) {
              if (personalBests.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No personal bests yet. Add training sessions to compare '
                      'your best times against USA Swimming motivational standards.',
                    ),
                  ),
                );
              }

              return Column(
                children: personalBests.map((pb) {
                  final comparisonAsync = ref.watch(
                    standardComparisonProvider((
                      event: pb.event,
                      timeSeconds: pb.timeSeconds,
                    )),
                  );

                  return comparisonAsync.when(
                    loading: () => Card(
                      child: ListTile(
                        title: Text(pb.event),
                        subtitle: Text(
                          'PB ${SwimTimeUtils.secondsToSwimTime(pb.timeSeconds)}',
                        ),
                        trailing: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (error, _) => Card(
                      child: ListTile(
                        title: Text(pb.event),
                        subtitle: Text('PB load error: $error'),
                      ),
                    ),
                    data: (comparison) {
                      if (comparison == null) {
                        return Card(
                          child: ListTile(
                            title: Text(pb.event),
                            subtitle: Text(
                              'PB ${SwimTimeUtils.secondsToSwimTime(pb.timeSeconds)} · '
                              'No matching standard for current filters',
                            ),
                          ),
                        );
                      }

                      return StandardProgressCard(
                        title: pb.event,
                        comparison: comparison,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
