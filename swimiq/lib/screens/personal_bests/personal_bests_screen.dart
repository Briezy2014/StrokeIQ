import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_time.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class PersonalBestsScreen extends ConsumerWidget {
  const PersonalBestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final personalBests = data.personalBests;
        final dateFormat = DateFormat.yMMMd();

        if (personalBests.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SwimIqScreenHeader(
                title: 'Personal Bests',
                subtitle: 'Fastest logged times for ${data.displayName(swimmer)}',
              ),
              const SizedBox(height: 16),
              const EmptyStateMessage(
                message:
                    'No personal bests yet. Add swim sessions to unlock this page.',
              ),
            ],
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqScreenHeader(
              title: 'Personal Bests',
              subtitle:
                  '${personalBests.length} events tracked for ${data.displayName(swimmer)}',
            ),
            const SizedBox(height: 16),
            ...personalBests.map(
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
                  title: '${log.distance} ${log.stroke}',
                  subtitle:
                      '${log.course} · ${dateFormat.format(log.date)} · $cut cut',
                  trailing: SwimTime.fromSeconds(log.timeSeconds),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
