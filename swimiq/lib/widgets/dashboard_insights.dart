import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/season_arc_service.dart';
import '../core/services/standards_gap_service.dart';
import '../core/services/wellness_readiness_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../screens/meet_day/meet_day_screen.dart';
import '../screens/swim_dna/swim_dna_screen.dart';
import '../screens/wellness/wellness_readiness_screen.dart';

String dashboardSubtitleForMode({
  required AppViewMode mode,
  required String displayName,
  required String swimIqExplanation,
}) {
  switch (mode) {
    case AppViewMode.athlete:
      return swimIqExplanation;
    case AppViewMode.parent:
      return 'Parent view — progress, wellness, and cuts for $displayName.';
    case AppViewMode.coach:
      return 'Coach view — workload, standards gaps, and season phase for $displayName.';
  }
}

class DashboardInsightCards extends ConsumerWidget {
  const DashboardInsightCards({
    super.key,
    required this.data,
    required this.swimmer,
  });

  final SwimmerData data;
  final String swimmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = SeasonArcService.build(data: data, swimmer: swimmer);
    final gap = StandardsGapService.build(data: data, swimmer: swimmer);
    final wellness = WellnessReadinessService.build(data: data, swimmer: swimmer);
    final viewMode = ref.watch(appViewModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          viewMode == AppViewMode.coach
              ? 'Coach insights'
              : viewMode == AppViewMode.parent
                  ? 'Family insights'
                  : 'Your insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          emoji: '📈',
          title: 'Season arc · ${season.currentPhase.name}',
          subtitle: season.currentPhase.focus,
          detail: '${season.currentPhase.weeksRemaining} weeks to target · '
              '${season.currentPhase.volumeGuidance}',
          source: 'Pulls from: Goals tab (nearest target date)',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeetDayScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        _InsightCard(
          emoji: '🎯',
          title: 'Standards gap',
          subtitle: gap.summary,
          detail: gap.closestTarget != null
              ? '${gap.closestTarget!.eventLabel} · ${gap.closestTarget!.standardLevel} '
                  '(${gap.closestTarget!.cutLabel})'
              : 'Top PB cut: ${gap.highestAchieved}',
          source:
              'Pulls from: Personal bests + Passport (birthday/gender) + USA standards JSON',
          progress: gap.closestTarget?.progressPercent,
        ),
        const SizedBox(height: 10),
        _InsightCard(
          emoji: '💚',
          title: wellness.readinessLabel,
          subtitle: 'Readiness ${wellness.readinessScore}/100',
          detail: wellness.factors.isNotEmpty
              ? wellness.factors.first
              : 'Log wellness check-in in Passport',
          source:
              'Pulls from: Passport wellness (sleep, soreness, illness) + training log',
          progress: wellness.readinessScore,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WellnessReadinessScreen()),
            );
          },
        ),
        if (viewMode != AppViewMode.athlete) ...[
          const SizedBox(height: 10),
          _InsightCard(
            emoji: '🧬',
            title: viewMode == AppViewMode.parent ? 'Athlete snapshot' : 'Athlete profile',
            subtitle: data.passportSnapshot(swimmer).readiness,
            detail: 'SwimIQ ${data.swimIqScore} · ${data.passportSnapshot(swimmer).highestCut}',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SwimDnaScreen()),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.detail,
    this.source,
    this.progress,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String detail;
  final String? source;
  final int? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (source != null) ...[
                const SizedBox(height: 6),
                Text(
                  source!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress! / 100,
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
