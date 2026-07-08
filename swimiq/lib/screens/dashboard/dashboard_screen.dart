import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/subscription/subscription_capabilities.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/schedule_depository_section.dart';
import '../../widgets/swimiq_rope_climb_card.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_logo.dart';
import '../../widgets/weekly_progress_report_card.dart';
import '../../core/gamification/swimiq_badges.dart';
import '../../core/gamification/swimiq_daily_progress.dart';
import '../membership/membership_screen.dart';
import '../race_intelligence/race_intelligence_screen.dart';
import '../dryland/ai_dryland_coach_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final logs = data.raceLogs;
        final meetResults = data.meetResults;
        final personalBests = data.personalBests;
        final hasAnyActivity = logs.isNotEmpty || meetResults.isNotEmpty;

        final subscription = ref.watch(subscriptionStateProvider).value;
        final showProFeatures = subscription != null &&
            SubscriptionCapabilities.canUseProFeatures(subscription);
        final showEliteFeatures = subscription != null &&
            SubscriptionCapabilities.hasEliteAccess(subscription);

        if (!hasAnyActivity) {
          final daily = SwimIqDailyProgress.calculate(
            raceLogs: logs,
            meetResults: meetResults,
            videos: data.userFacingVideos,
            goals: data.goals,
            overallSwimIqScore: 0,
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
            snapshot: data.passportSnapshot(swimmer),
          );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _DashboardHero(
                displayName: data.displayName(swimmer),
                swimIqScore: 0,
                highestCut: showProFeatures ? 'Start logging' : 'Log to track',
                spotlight: null,
                profile: data.profile,
                catalog: data.motivationalStandards,
              ),
              const SizedBox(height: 16),
              SwimIqRopeClimbCard(daily: daily, badges: badges),
              const SizedBox(height: 16),
              WeeklyProgressReportCard(raceLogs: logs, goals: data.goals),
              const SizedBox(height: 16),
              if (!showProFeatures) ...[
                const _DashboardProUpsell(),
                const SizedBox(height: 16),
              ],
              const EmptyStateMessage(
                message:
                    'No swim sessions yet. Log training on the Log tab to get started.',
              ),
              if (showProFeatures) ...[
                const SizedBox(height: 20),
                ScheduleDepositorySection(
                  compact: true,
                  onOpenRaceIntelligence: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RaceIntelligenceScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        }

        final snapshot = data.passportSnapshot(swimmer);
        final spotlight = SwimAnalytics.spotlightPersonalBest(
          personalBests: personalBests,
          catalog: data.motivationalStandards,
          profile: data.profile,
        );
        final dateFormat = DateFormat.yMMMd();
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
            _DashboardHero(
              displayName: data.displayName(swimmer),
              swimIqScore: data.swimIqScore,
              highestCut: showProFeatures ? snapshot.highestCut : 'Log to track',
              spotlight: showProFeatures ? spotlight : null,
              profile: data.profile,
              catalog: data.motivationalStandards,
            ),
            const SizedBox(height: 16),
            SwimIqRopeClimbCard(daily: daily, badges: badges),
            const SizedBox(height: 16),
            WeeklyProgressReportCard(raceLogs: logs, goals: data.goals),
            const SizedBox(height: 16),
            if (!showProFeatures) ...[
              const _DashboardProUpsell(),
              const SizedBox(height: 16),
            ],
            if (showProFeatures) ...[
              _ActivityStrip(
                sessions: logs.length,
                goals: data.goals.length,
                meets: meetResults.length,
                personalBests: personalBests.length,
                videos: data.userFacingVideoAnalyses.length,
              ),
              const SizedBox(height: 16),
              _DrylandCoachCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AiDrylandCoachScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ScheduleDepositorySection(
                compact: true,
                onOpenRaceIntelligence: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RaceIntelligenceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            if (showProFeatures && !showEliteFeatures) ...[
              const _DashboardEliteUpsell(),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            if (showProFeatures)
              ...personalBests.take(5).map(
                (pb) {
                  final cut = MotivationalCut.labelForSwim(
                    catalog: data.motivationalStandards,
                    profile: data.profile,
                    stroke: pb.stroke,
                    distance: pb.distance,
                    course: pb.course,
                    timeSeconds: pb.timeSeconds,
                  );
                  return _ActivityTile(
                    title: pb.displayTitle,
                    subtitle:
                        '${pb.course} · ${pb.sourceLabel} · ${dateFormat.format(pb.date)} · $cut cut',
                    trailing: pb.formattedTime,
                    highlight: cut == snapshot.highestCut,
                  );
                },
              )
            else if (logs.isEmpty)
              const EmptyStateMessage(
                message:
                    'Log a training session on the Log tab. Your progress charts update automatically.',
              )
            else
              ...logs.take(5).map(
                (log) => _ActivityTile(
                  title: log.event,
                  subtitle: dateFormat.format(log.date),
                  trailing: SwimTime.fromSeconds(log.timeSeconds),
                ),
              ),
            if (logs.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Training Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _TimeProgressChart(logs: logs),
                  ),
                ),
              ),
            ],
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
    required this.spotlight,
    required this.profile,
    required this.catalog,
  });

  final String displayName;
  final int swimIqScore;
  final String highestCut;
  final PersonalBestEntry? spotlight;
  final SwimmerProfile? profile;
  final UsaMotivationalStandardsCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final spotlightCut = spotlight == null
        ? null
        : MotivationalCut.labelForSwim(
            catalog: catalog,
            profile: profile,
            stroke: spotlight!.stroke,
            distance: spotlight!.distance,
            course: spotlight!.course,
            timeSeconds: spotlight!.timeSeconds,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.accent,
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'WELCOME BACK, ${displayName.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
                ),
              ),
              const SwimIqCompactMark(size: 44, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$swimIqScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'SwimIQ\nScore',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              _CutBadge(label: highestCut, large: true),
            ],
          ),
          if (spotlight != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPOTLIGHT PB',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${spotlight!.displayTitle} · ${spotlight!.course}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${spotlight!.formattedTime} · ${spotlight!.sourceLabel}'
                    '${spotlight!.meetName != null ? ' · ${spotlight!.meetName}' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (spotlightCut != null) ...[
                    const SizedBox(height: 10),
                    _CutBadge(label: spotlightCut),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CutBadge extends StatelessWidget {
  const _CutBadge({required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w900,
          fontSize: large ? 16 : 13,
        ),
      ),
    );
  }
}

class _ActivityStrip extends StatelessWidget {
  const _ActivityStrip({
    required this.sessions,
    required this.goals,
    required this.meets,
    required this.personalBests,
    required this.videos,
  });

  final int sessions;
  final int goals;
  final int meets;
  final int personalBests;
  final int videos;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ChipStat(label: 'Sessions', value: '$sessions'),
        _ChipStat(label: 'Goals', value: '$goals'),
        _ChipStat(label: 'Meets', value: '$meets'),
        _ChipStat(label: 'PBs', value: '$personalBests'),
        _ChipStat(label: 'AI Videos', value: '$videos'),
      ],
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.comingSoonBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.comingSoonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrylandCoachCard extends StatelessWidget {
  const _DrylandCoachCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Dryland Coach',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalized strength, core, mobility, stability & recovery',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardProUpsell extends StatelessWidget {
  const _DashboardProUpsell();

  static const _features = [
    'Official PBs, meet results & USA Swimming standards',
    'Athlete Passport & Recruiting Snapshot',
    'Video Lab (upload & organize videos)',
    'AI Dryland Coach — strength, core & mobility',
  ];

  @override
  Widget build(BuildContext context) {
    final pro = SubscriptionCatalog.planFor(SubscriptionTier.pro);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pro.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (pro.badgeLabel ?? 'Most Popular').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You have Basic — great foundation. Upgrade to Pro for official meet '
              'tracking, USA standards, passport, video library, and AI Dryland Coach.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),
            ..._features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MembershipScreen(),
                  ),
                );
              },
              child: Text('Upgrade to ${pro.name}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEliteUpsell extends StatelessWidget {
  const _DashboardEliteUpsell();

  static const _features = [
    'AI Stroke Analysis — mechanics, kick, turns & more',
    'Race Intelligence — pacing, splits & fatigue detection',
    'AI Performance Reports & race strategy',
  ];

  @override
  Widget build(BuildContext context) {
    final elite = SubscriptionCatalog.planFor(SubscriptionTier.elite);

    return Card(
      color: AppColors.textDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    elite.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (elite.badgeLabel ?? 'Advanced AI Performance').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You have Pro — powerful competitive tools. Elite adds AI stroke analysis '
              'from your race footage and advanced race intelligence.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            ..._features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_outlined,
                        size: 18, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MembershipScreen(),
                  ),
                );
              },
              child: Text('Upgrade to ${elite.name}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlight ? AppColors.primary : Colors.grey.shade200,
          width: highlight ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          trailing,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TimeProgressChart extends StatelessWidget {
  const _TimeProgressChart({required this.logs});

  final List<RaceLog> logs;

  static const _strokeColors = {
    'Freestyle': Color(0xFF009CFF),
    'Backstroke': Color(0xFF38B6FF),
    'Breaststroke': Color(0xFF0077C8),
    'Butterfly': Color(0xFF0B5CAD),
    'IM': Color(0xFF0B2D4D),
    'Free': Color(0xFF009CFF),
  };

  @override
  Widget build(BuildContext context) {
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final strokes = sorted.map((log) => log.stroke).toSet().toList();

    final lineBars = <LineChartBarData>[];
    for (final stroke in strokes) {
      final strokeLogs = sorted.where((log) => log.stroke == stroke).toList();
      final spots = <FlSpot>[];
      for (var i = 0; i < strokeLogs.length; i++) {
        spots.add(FlSpot(i.toDouble(), strokeLogs[i].timeSeconds));
      }
      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _strokeColors[stroke] ?? Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      );
    }

    if (lineBars.isEmpty) {
      return const Center(child: Text('Not enough data for chart.'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sorted.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.Md().format(sorted[index].date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                SwimTime.fromSeconds(value),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBars,
      ),
    );
  }
}
