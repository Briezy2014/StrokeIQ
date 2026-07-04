import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/app_providers.dart';
import '../utils/personal_bests.dart';
import '../widgets/empty_state.dart';

class PersonalBestsScreen extends ConsumerWidget {
  const PersonalBestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(swimmerDataProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load personal bests: $error')),
      data: (data) {
        final pbs = PersonalBests.fromRaceLogs(data.raceLogs);

        if (pbs.isEmpty) {
          return const EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No personal bests yet',
            message: 'Add swim sessions to unlock your personal bests.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refreshData(ref),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pbs.length,
            itemBuilder: (context, index) {
              final pb = pbs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: SwimIQTheme.heroGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pb.distance} ${pb.stroke}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pb.course} · ${pb.date}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        pb.formattedTime,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: SwimIQTheme.darkNavy,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
