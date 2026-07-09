import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/meet_history_analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';

class MeetHistoryScreen extends ConsumerWidget {
  const MeetHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.pro,
      title: 'Unlock SwimIQ Pro',
      message: 'Meet History is included with Pro.',
      teaserFeatures: const [
        'Meet attendance tracking',
        'Season-by-season improvement',
        'Lifetime progression & championship highlights',
      ],
      child: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final summary = MeetHistoryAnalytics.build(
            meetResults: data.meetResults,
            personalBests: data.personalBests,
          );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SwimIqPageHero(
                title: 'Meet History',
                subtitle: 'College coaches love consistency — track attendance '
                    'and improvement over seasons.',
              ),
              const SizedBox(height: 16),
              _StatRow(
                meets: summary.totalMeets,
                swims: summary.totalSwims,
              ),
              if (summary.meetNames.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Meet attendance',
                  lines: summary.meetNames,
                ),
              ],
              if (summary.seasonSummaries.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...summary.seasonSummaries.map(
                  (season) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SectionCard(
                      title: season.seasonLabel,
                      lines: [
                        '${season.meetCount} meets · ${season.swimCount} swims',
                        ...season.bestSwims.map((s) => 'Best: $s'),
                      ],
                    ),
                  ),
                ),
              ],
              if (summary.progressionLines.isNotEmpty) ...[
                const SizedBox(height: 4),
                _SectionCard(
                  title: 'Lifetime progression',
                  lines: summary.progressionLines,
                ),
              ],
              if (summary.championshipHighlights.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Best championship swims',
                  lines: summary.championshipHighlights,
                ),
              ],
              if (summary.totalMeets == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Log meet results on the Meets tab to build your history.',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.meets, required this.swims});

  final int meets;
  final int swims;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Meets attended', value: '$meets'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'Total swims', value: '$swims'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
