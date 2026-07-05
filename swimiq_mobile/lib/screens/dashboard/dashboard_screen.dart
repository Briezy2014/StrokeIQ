import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../providers/race_log_providers.dart';
import '../../providers/standards_providers.dart';
import '../../services/standards_analytics.dart';
import '../../widgets/standards/standard_progress_card.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/swimiq_app_bar.dart';

/// Dashboard with motivational standards summary.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swimmerName = ref.watch(currentSwimmerNameProvider);
    final email = ref.watch(currentUserEmailProvider);
    final standardsLoaded = ref.watch(standardsLoadedProvider);
    final personalBestsAsync = ref.watch(personalBestsProvider);
    final ageGroup = ref.watch(resolvedAgeGroupProvider);

    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Dashboard'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${swimmerName ?? 'Swimmer'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('Signed in as ${email ?? 'unknown'}'),
                  if (ageGroup != null) ...[
                    const SizedBox(height: 8),
                    Text('Motivational age group: $ageGroup'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!standardsLoaded)
            const StandardsEmptyState()
          else
            personalBestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Could not load standards summary: $error'),
              data: (personalBests) {
                if (personalBests.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Add training sessions to see your current motivational '
                        'level, next standard, and progress bars here.',
                      ),
                    ),
                  );
                }

                final comparisons = <StandardComparison>[];
                for (final pb in personalBests.take(3)) {
                  final comparison = ref
                      .watch(
                        standardComparisonProvider((
                          event: pb.event,
                          timeSeconds: pb.timeSeconds,
                        )),
                      )
                      .value;
                  if (comparison != null) {
                    comparisons.add(comparison);
                  }
                }

                final highest = StandardsAnalytics.highestAcrossComparisons(comparisons);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.military_tech_outlined),
                        title: const Text('Highest motivational level'),
                        subtitle: Text(highest?.label ?? 'Below B'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...comparisons.map(
                      (comparison) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StandardProgressCard(
                          title: comparison.standard.event,
                          comparison: comparison,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => context.go('/home/standards'),
                child: const Text('USA Standards'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/home/personal-bests'),
                child: const Text('Personal Bests'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
