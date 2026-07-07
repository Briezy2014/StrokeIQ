import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/motivational_cut.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimmer_screen.dart';

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
              Text(
                'Personal Bests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fastest official meet times for ${data.displayName(swimmer)}',
              ),
              const SizedBox(height: 16),
              const EmptyStateMessage(
                message:
                    'No personal bests yet. Add meet results on the Meets tab to unlock this page.',
              ),
            ],
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Personal Bests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${personalBests.length} events tracked from meet results',
            ),
            const SizedBox(height: 16),
            ...personalBests.map(
              (pb) {
                final cut = MotivationalCut.labelForSwim(
                  catalog: data.motivationalStandards,
                  profile: data.profile,
                  stroke: pb.stroke,
                  distance: pb.distance,
                  course: pb.course,
                  timeSeconds: pb.timeSeconds,
                );
                final sourceDetail = pb.meetName ?? pb.eventLabel;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      pb.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${pb.course} · ${pb.sourceLabel} · ${dateFormat.format(pb.date)}\n'
                      '$sourceDetail · $cut cut',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      pb.formattedTime,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
