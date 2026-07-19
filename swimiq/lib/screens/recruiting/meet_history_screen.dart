import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/meet_history_analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';

/// Career highlights for recruiting — season bests & progression (not attendance).
class MeetHistoryScreen extends ConsumerWidget {
  const MeetHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimIqFeatureScaffold(
      title: 'Career Highlights',
      body: SubscriptionGatedScreen(
        minimumTier: SubscriptionTier.pro,
        title: 'Unlock SwimIQ Pro',
        message: 'Career Highlights is included with Pro.',
        teaserFeatures: const [
          'Season-best times by event',
          'Lifetime progression on key events',
          'Top recruiting highlight swims',
        ],
        child: SwimmerScreen(
          builder: (context, ref, data, swimmer) {
            final summary = MeetHistoryAnalytics.build(
              meetResults: data.meetResults,
              personalBests: data.personalBests,
            );
            final hasContent = summary.totalSwims > 0 ||
                summary.highlightSwims.isNotEmpty;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const _HighlightsHeader(),
                const SizedBox(height: 16),
                _StatRow(
                  events: summary.eventCount,
                  swims: summary.totalSwims,
                  meets: summary.realMeetCount,
                ),
                if (summary.seasonSummaries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...summary.seasonSummaries.map(
                    (season) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SectionCard(
                        title: season.seasonLabel,
                        lines: [
                          if (season.meetCount > 0)
                            '${season.meetCount} meets · ${season.swimCount} timed swims'
                          else
                            '${season.swimCount} timed swims this season',
                          ...season.bestSwims.map((s) => 'Best: $s'),
                        ],
                      ),
                    ),
                  ),
                ],
                if (summary.progressionLines.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Lifetime progression',
                    subtitle: 'How key events have moved over time',
                    lines: summary.progressionLines,
                  ),
                  const SizedBox(height: 12),
                ],
                if (summary.highlightSwims.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Highlight swims',
                    subtitle: 'Top times coaches notice first',
                    lines: summary.highlightSwims,
                  ),
                ],
                if (!hasContent)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Log meet results or upload best times on the PBs tab '
                          'to build your career highlights.',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HighlightsHeader extends StatelessWidget {
  const _HighlightsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Career Highlights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Season bests, lifetime progression, and the swims that tell your story.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.events,
    required this.swims,
    required this.meets,
  });

  final int events;
  final int swims;
  final int meets;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Events tracked', value: '$events'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'Timed swims', value: '$swims'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'Real meets', value: '$meets'),
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.lines,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: AppColors.primaryDeep.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
