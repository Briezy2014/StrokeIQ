import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_time.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimiq_rope_climb_card.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_logo.dart';
import '../../core/gamification/swimiq_badges.dart';
import '../../core/gamification/swimiq_daily_progress.dart';
import '../membership/membership_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final logs = data.raceLogs;
        final meetResults = data.meetResults;
        final personalBests = data.personalBests;

        final subscription = ref.watch(subscriptionStateProvider).value;
        final showProFeatures = subscription != null &&
            SubscriptionCapabilities.canUseProFeatures(subscription);
        final showEliteFeatures = subscription != null &&
            SubscriptionCapabilities.hasEliteAccess(subscription);

        final snapshot = data.passportSnapshot(swimmer);
        final daily = SwimIqDailyProgress.calculate(
          raceLogs: logs,
          meetResults: meetResults,
          videos: data.userFacingVideos,
          goals: data.goals,
          overallSwimIqScore: data.swimIqScore,
        );
        final badges = SwimIqBadgeCatalog.evaluate(
          daily: daily,
          raceLogs: logs,
          meetResults: meetResults,
          goals: data.goals,
          personalBests: personalBests,
          videos: data.userFacingVideos,
          analyses: data.userFacingVideoAnalyses,
          profile: data.profile,
          snapshot: snapshot,
        );

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                AppConstants.previewBuildLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDeep,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _DashboardHero(
              displayName: data.displayName(swimmer),
              swimIqScore: data.swimIqScore,
              highestCut: showProFeatures
                  ? snapshot.highestCut
                  : (logs.isEmpty ? 'Log swims to score' : 'Upgrade for cuts'),
              climbPercent: daily.ropeClimbPercent,
            ),
            const SizedBox(height: 16),
            SwimIqRopeClimbCard(daily: daily, badges: badges),
            const SizedBox(height: 16),
            _EventCutsProgressSection(
              personalBests: personalBests,
              raceLogs: logs,
              catalog: data.motivationalStandards,
              profile: data.profile,
              showProFeatures: showProFeatures,
              highestCut: snapshot.highestCut,
              onOpenLogTab: () {
                ref.read(trainingLogSegmentProvider.notifier).state = 0;
                ref.read(homeTabIndexProvider.notifier).state = HomeTab.trainingLog;
              },
              onOpenMeetsTab: () {
                ref.read(trainingLogSegmentProvider.notifier).state = 1;
                ref.read(homeTabIndexProvider.notifier).state = HomeTab.trainingLog;
              },
            ),
            if (!showProFeatures) ...[
              const SizedBox(height: 16),
              const _DashboardProUpsell(),
            ],
            if (showProFeatures && !showEliteFeatures) ...[
              const SizedBox(height: 16),
              const _DashboardEliteUpsell(),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.displayName,
    required this.swimIqScore,
    required this.highestCut,
    required this.climbPercent,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final int climbPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SwimIqCompactMark(size: 40, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$swimIqScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'SwimIQ Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(label: 'Highest cut: $highestCut'),
              _HeroChip(label: '$climbPercent% up the rope'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EventCutsProgressSection extends StatelessWidget {
  const _EventCutsProgressSection({
    required this.personalBests,
    required this.raceLogs,
    required this.catalog,
    required this.profile,
    required this.showProFeatures,
    required this.highestCut,
    required this.onOpenLogTab,
    required this.onOpenMeetsTab,
  });

  final List<PersonalBestEntry> personalBests;
  final List<RaceLog> raceLogs;
  final UsaMotivationalStandardsCatalog catalog;
  final SwimmerProfile? profile;
  final bool showProFeatures;
  final String highestCut;
  final VoidCallback onOpenLogTab;
  final VoidCallback onOpenMeetsTab;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Events & USA cuts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Top times and motivational standards per event.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 14),
            if (showProFeatures && personalBests.isNotEmpty)
              ...personalBests.take(8).map((pb) {
                final cut = MotivationalCut.labelForSwim(
                  catalog: catalog,
                  profile: profile,
                  stroke: pb.stroke,
                  distance: pb.distance,
                  course: pb.course,
                  timeSeconds: pb.timeSeconds,
                );
                return _EventProgressTile(
                  title: pb.displayTitle,
                  subtitle:
                      '${pb.course} · ${pb.formattedTime} · ${dateFormat.format(pb.date)}',
                  cutLabel: cut,
                  highlight: cut == highestCut,
                );
              })
            else if (!showProFeatures && raceLogs.isNotEmpty)
              ..._sessionSummaries(raceLogs, dateFormat)
            else
              EmptyStateMessage(
                message: showProFeatures
                    ? 'No official meet times yet. Add results on the Meets tab.'
                    : 'Log training on the Log tab. Upgrade to Pro for USA cuts per event.',
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenLogTab,
                    icon: const Icon(Icons.list_alt_outlined, size: 18),
                    label: const Text('Log tab'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenMeetsTab,
                    icon: const Icon(Icons.stadium_outlined, size: 18),
                    label: const Text('Log meets'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sessionSummaries(List<RaceLog> logs, DateFormat dateFormat) {
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final byEvent = <String, RaceLog>{};
    for (final log in sorted) {
      final key = '${log.distance} ${log.stroke} (${log.course})';
      final existing = byEvent[key];
      if (existing == null || log.timeSeconds < existing.timeSeconds) {
        byEvent[key] = log;
      }
    }
    return byEvent.entries.map((entry) {
      final log = entry.value;
      return _EventProgressTile(
        title: entry.key,
        subtitle: 'Best session · ${dateFormat.format(log.date)}',
        cutLabel: SwimTime.fromSeconds(log.timeSeconds),
        highlight: false,
      );
    }).toList();
  }
}

class _EventProgressTile extends StatelessWidget {
  const _EventProgressTile({
    required this.title,
    required this.subtitle,
    required this.cutLabel,
    required this.highlight,
  });

  final String title;
  final String subtitle;
  final String cutLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.grey.shade200,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              cutLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardProUpsell extends StatelessWidget {
  const _DashboardProUpsell();

  @override
  Widget build(BuildContext context) {
    final pro = SubscriptionCatalog.planFor(SubscriptionTier.pro);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.workspace_premium, color: AppColors.primary),
        title: Text('Unlock ${pro.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text('Official meet PBs, USA cuts, passport & video lab'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MembershipScreen()),
        ),
      ),
    );
  }
}

class _DashboardEliteUpsell extends StatelessWidget {
  const _DashboardEliteUpsell();

  @override
  Widget build(BuildContext context) {
    final elite = SubscriptionCatalog.planFor(SubscriptionTier.elite);
    return Card(
      color: AppColors.textDark,
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.white),
        title: Text(
          'Unlock ${elite.name}',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        subtitle: Text(
          'AI stroke analysis & Race Intelligence',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.9)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MembershipScreen()),
        ),
      ),
    );
  }
}
