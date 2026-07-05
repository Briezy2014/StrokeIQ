import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/profile_providers.dart';
import '../../providers/race_log_providers.dart';
import '../../providers/standards_providers.dart';
import '../../services/standards_analytics.dart';
import '../../widgets/standards/standard_progress_card.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/swimiq_app_bar.dart';
import '../../widgets/swimiq_logo.dart';

/// Athlete Passport profile view (read-only for now).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(swimmerProfileProvider);
    final standardsLoaded = ref.watch(standardsLoadedProvider);
    final personalBestsAsync = ref.watch(personalBestsProvider);

    return Scaffold(
      appBar: SwimIqAppBar(
        subtitle: 'Athlete Passport',
        actions: [
          IconButton(
            onPressed: () => context.push('/home/profile/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load profile: $error'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No swimmer profile found yet. It should be created '
                  'automatically when you sign up.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: SwimIqColors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: SwimIqColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    const SwimIqLogo(
                      variant: SwimIqLogoVariant.appIcon,
                      width: 88,
                      height: 88,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.team ?? 'Team not added yet',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileTile(
                label: 'Swimmer code',
                value: profile.swimmerName,
              ),
              _ProfileTile(
                label: 'Coach',
                value: profile.coachName ?? 'Not added yet',
              ),
              _ProfileTile(
                label: 'Primary stroke',
                value: profile.primaryStroke ?? 'Not added yet',
              ),
              _ProfileTile(
                label: 'Favorite event',
                value: profile.favoriteEvent ?? 'Not added yet',
              ),
              _ProfileTile(
                label: 'School',
                value: profile.school ?? 'Not added yet',
              ),
              const SizedBox(height: 16),
              Text(
                'Motivational Standards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (!standardsLoaded)
                const StandardsEmptyState(compact: true)
              else
                personalBestsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text('Standards summary error: $error'),
                  data: (personalBests) {
                    final comparisons = <StandardComparison>[];
                    for (final pb in personalBests) {
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

                    final highest =
                        StandardsAnalytics.highestAcrossComparisons(comparisons);

                    return Column(
                      children: [
                        _ProfileTile(
                          label: 'Highest motivational level',
                          value: highest?.label ?? 'Below B',
                        ),
                        ...comparisons.take(2).map(
                              (comparison) => Padding(
                                padding: const EdgeInsets.only(top: 8),
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
              OutlinedButton(
                onPressed: () => context.push('/home/standards'),
                child: const Text('Open USA Standards'),
              ),
              OutlinedButton(
                onPressed: () => context.push('/home/video-lab'),
                child: const Text('Video Lab'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Full profile editing will be added in a later milestone.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
