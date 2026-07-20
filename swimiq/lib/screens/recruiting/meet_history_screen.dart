import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/career_highlights.dart';
import '../../core/recruiting/meet_history_analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';

/// Career Highlights — recruiter-friendly auto cards + progression pulse.
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
          'Highest USA standard & career achievement',
          'Biggest lifetime time drops',
          'SwimIQ rating + progression pulse',
        ],
        child: SwimmerScreen(
          builder: (context, ref, data, swimmer) {
            final highlights = CareerHighlightsBuilder.build(
              meetResults: data.meetResults,
              personalBests: data.personalBests,
              goals: data.goals,
              raceLogs: data.raceLogs,
              catalog: data.motivationalStandards,
              profile: data.profile,
              swimIqScore: data.swimIqScore,
              videoAnalyses: data.userFacingVideoAnalyses,
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const _HighlightsHeader(),
                if (highlights.hasAnything) ...[
                  const SizedBox(height: 14),
                  _ProgressionPulse(summary: highlights),
                ],
                if (highlights.cards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Highlight cards',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap any card for the recruiting story behind it.',
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 640;
                      final cards = highlights.cards;
                      if (!wide) {
                        return Column(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              _HighlightCard(item: cards[i], index: i),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      }
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < cards.length; i++)
                            SizedBox(
                              width: (constraints.maxWidth - 10) / 2,
                              child: _HighlightCard(item: cards[i], index: i),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                if (highlights.history.seasonSummaries.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Season bests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...highlights.history.seasonSummaries.take(2).map(
                        (season) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SeasonCard(season: season),
                        ),
                      ),
                ],
                if (!highlights.hasAnything)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Log meet results or upload best times on the PBs tab '
                          'to build recruiter-ready career highlights.',
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
            'The recruiter snapshot — achievements, drops, standards, and SwimIQ rating.',
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

class _ProgressionPulse extends StatelessWidget {
  const _ProgressionPulse({required this.summary});

  final CareerHighlightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final cells = <({String label, String value})>[
      (label: 'Meets', value: '${summary.meets}'),
      (label: 'Races', value: '${summary.races}'),
      (label: 'Lifetime PBs', value: '${summary.lifetimePbs}'),
      if (summary.yearsCompetitive != null)
        (label: 'Years', value: '${summary.yearsCompetitive}'),
      if (summary.highestCut != null)
        (label: 'USA Cut', value: summary.highestCut!),
      if (summary.swimIqScore > 0)
        (label: 'Rating', value: summary.swimIqRating),
      if (summary.improvementTrendPercent != null)
        (
          label: 'Trend',
          value: '+${summary.improvementTrendPercent}%',
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Career progression pulse',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'IM-style snapshot coaches can scan in seconds.',
            style: TextStyle(
              color: AppColors.textDark.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cell in cells)
                _PulseChip(label: cell.label, value: cell.value),
            ],
          ),
          if (summary.swimIqScore > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (summary.swimIqScore / 1000).clamp(0.08, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SwimIQ Score ${summary.swimIqScore} · ${summary.swimIqRating}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseChip extends StatelessWidget {
  const _PulseChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.primaryDeep,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: AppColors.textDark.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.item, this.index = 0});

  final CareerHighlightItem item;
  final int index;

  IconData get _icon {
    switch (item.iconName) {
      case 'military_tech':
        return Icons.military_tech;
      case 'trending_down':
        return Icons.trending_down;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'speed':
        return Icons.speed;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'flag':
        return Icons.flag;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'workspace_premium':
        return Icons.workspace_premium;
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final delayMs = (index * 55).clamp(0, 280);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(context),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _icon,
                        color: AppColors.primaryDeep,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.primary.withValues(alpha: 0.55),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    height: 1.15,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textDark.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(_icon, color: AppColors.primaryDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: AppColors.primaryDeep,
                ),
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
              if (item.detail != null) ...[
                const SizedBox(height: 12),
                Text(
                  item.detail!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.season});

  final SeasonHighlightSummary season;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              season.seasonLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              season.meetCount > 0
                  ? '${season.meetCount} meets · ${season.swimCount} timed swims'
                  : '${season.swimCount} timed swims this season',
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            for (final swim in season.bestSwims.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  swim,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
