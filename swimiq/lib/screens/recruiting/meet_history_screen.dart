import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/recruiting/career_highlights.dart';
import '../../core/recruiting/meet_history_analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';

/// Career Highlights — recruiter-facing visual showcase.
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
            final featured =
                highlights.cards.isEmpty ? null : highlights.cards.first;
            final rest = highlights.cards.length <= 1
                ? const <CareerHighlightItem>[]
                : highlights.cards.sublist(1);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _AtmosphereHero(
                  swimmerName: data.displayName(swimmer),
                  hasHighlights: highlights.hasAnything,
                  featured: featured,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (highlights.hasAnything) ...[
                        const SizedBox(height: 18),
                        _ProgressionPulse(summary: highlights),
                        if (rest.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _SectionLabel(
                            title: 'Recruiting reel',
                            subtitle:
                                'Tap a highlight for the story coaches care about.',
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 640;
                              if (!wide) {
                                return Column(
                                  children: [
                                    for (var i = 0; i < rest.length; i++) ...[
                                      _HighlightCard(item: rest[i], index: i),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                              }
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (var i = 0; i < rest.length; i++)
                                    SizedBox(
                                      width: (constraints.maxWidth - 12) / 2,
                                      child: _HighlightCard(
                                        item: rest[i],
                                        index: i,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                        if (highlights.history.seasonSummaries.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const _SectionLabel(
                            title: 'Season bests',
                            subtitle: 'Recent seasons recruiters ask about.',
                          ),
                          const SizedBox(height: 12),
                          ...highlights.history.seasonSummaries.take(2).map(
                                (season) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SeasonStrip(season: season),
                                ),
                              ),
                        ],
                      ] else ...[
                        const SizedBox(height: 20),
                        const _EmptyHighlightsVisual(),
                      ],
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textDark.withValues(alpha: 0.68),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Full-bleed pool atmosphere + featured achievement medal.
class _AtmosphereHero extends StatelessWidget {
  const _AtmosphereHero({
    required this.swimmerName,
    required this.hasHighlights,
    required this.featured,
  });

  final String swimmerName;
  final bool hasHighlights;
  final CareerHighlightItem? featured;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: hasHighlights && featured != null ? 320 : 220,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF063A72),
              AppColors.primaryDeep,
              AppColors.primary,
              Color(0xFF4AC2FF),
            ],
            stops: [0.0, 0.35, 0.72, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PoolLanePainter()),
            ),
            Positioned(
              right: -40,
              top: -30,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -20,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SWIMIQ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 3.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Career Highlights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasHighlights
                        ? '$swimmerName · recruiter-ready story from meets, cuts & PBs'
                        : 'Your championship reel builds here as meets and best times land.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  if (featured != null) ...[
                    const SizedBox(height: 22),
                    _FeaturedMedal(item: featured!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedMedal extends StatelessWidget {
  const _FeaturedMedal({required this.item});

  final CareerHighlightItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openHighlightDetail(context, item),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFE08A),
                        Color(0xFFF5C542),
                        Color(0xFFE8A317),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5C542).withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _iconFor(item.iconName),
                    color: const Color(0xFF5A3A00),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressionPulse extends StatelessWidget {
  const _ProgressionPulse({required this.summary});

  final CareerHighlightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final meters = <({String label, String value, double fill})>[
      (
        label: 'Meets',
        value: '${summary.meets}',
        fill: (summary.meets / 20).clamp(0.12, 1.0),
      ),
      (
        label: 'Races',
        value: '${summary.races}',
        fill: (summary.races / 40).clamp(0.12, 1.0),
      ),
      (
        label: 'Lifetime PBs',
        value: '${summary.lifetimePbs}',
        fill: (summary.lifetimePbs / 12).clamp(0.12, 1.0),
      ),
      if (summary.yearsCompetitive != null)
        (
          label: 'Years',
          value: '${summary.yearsCompetitive}',
          fill: ((summary.yearsCompetitive ?? 1) / 8).clamp(0.12, 1.0),
        ),
      if (summary.highestCut != null)
        (
          label: 'USA Cut',
          value: summary.highestCut!,
          fill: 0.92,
        ),
      if (summary.improvementTrendPercent != null)
        (
          label: 'Trend',
          value: '+${summary.improvementTrendPercent}%',
          fill: ((summary.improvementTrendPercent ?? 0) / 20).clamp(0.2, 1.0),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceLight,
            Colors.white,
            AppColors.comingSoonBg,
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waves_rounded,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression pulse',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                    ),
                    Text(
                      'Lane-by-lane scan coaches understand in seconds.',
                      style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < meters.length; i++) ...[
            _LaneMeter(
              label: meters[i].label,
              value: meters[i].value,
              fill: meters[i].fill,
              delayMs: i * 70,
            ),
            if (i != meters.length - 1) const SizedBox(height: 10),
          ],
          if (summary.swimIqScore > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.primaryDeep.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    color: AppColors.primaryDeep,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SwimIQ ${summary.swimIqRating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: (summary.swimIqScore / 1000).clamp(0.08, 1.0),
                          ),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                color: AppColors.primaryDeep,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${summary.swimIqScore}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LaneMeter extends StatelessWidget {
  const _LaneMeter({
    required this.label,
    required this.value,
    required this.fill,
    required this.delayMs,
  });

  final String label;
  final String value;
  final double fill;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fill.clamp(0.0, 1.0)),
      duration: Duration(milliseconds: 650 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.textDark.withValues(alpha: 0.72),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: t,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 64,
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.item, this.index = 0});

  final CareerHighlightItem item;
  final int index;

  Color get _accent {
    switch (item.id) {
      case 'usa_standard':
      case 'career_achievement':
        return const Color(0xFFE8A317);
      case 'biggest_drop':
      case 'most_improved':
        return const Color(0xFF2ECC71);
      case 'swimiq_rating':
        return AppColors.primary;
      case 'technical_strength':
        return const Color(0xFF2BB0A6);
      case 'goal_rate':
        return const Color(0xFF5B8DEF);
      default:
        return AppColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final delayMs = (index * 55).clamp(0, 280);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openHighlightDetail(context, item),
          child: Ink(
            height: 148,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  accent.withValues(alpha: 0.08),
                  AppColors.surfaceLight,
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: -12,
                  child: Icon(
                    _iconFor(item.iconName),
                    size: 92,
                    color: accent.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              _iconFor(item.iconName),
                              color: accent,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: accent.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.3,
                          color: AppColors.textDark.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          height: 1.12,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textDark.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeasonStrip extends StatelessWidget {
  const _SeasonStrip({required this.season});

  final SeasonHighlightSummary season;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniLanePainter(
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
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
              const SizedBox(height: 10),
              for (final swim in season.bestSwims.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
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
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHighlightsVisual extends StatelessWidget {
  const _EmptyHighlightsVisual();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.96 + (0.04 * t),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B5CAD),
              Color(0xFF1478D4),
              Color(0xFFEAF8FF),
            ],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(painter: _EmptyPoolPainter()),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your highlight reel is waiting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload best times on the PBs tab or log meet results — '
              'SwimIQ builds the achievement medal, USA cuts, and drops automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoolLanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 2;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const lanes = 5;
    for (var i = 1; i < lanes; i++) {
      final y = size.height * (i / lanes);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lanePaint);
    }

    // Center dashed race line
    final midY = size.height * 0.5;
    const dash = 10.0;
    const gap = 8.0;
    var x = 12.0;
    while (x < size.width - 12) {
      canvas.drawLine(
        Offset(x, midY),
        Offset(math.min(x + dash, size.width - 12), midY),
        dashPaint,
      );
      x += dash + gap;
    }

    // Soft wave arcs
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.68,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.92,
        size.width,
        size.height * 0.74,
      );
    canvas.drawPath(path, wave);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniLanePainter extends CustomPainter {
  _MiniLanePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLanePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _EmptyPoolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final water = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Offset.zero & size);

    final pool = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 18, size.width - 24, size.height - 28),
      const Radius.circular(18),
    );
    canvas.drawRRect(pool, water);

    final lane = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (var i = 1; i < 4; i++) {
      final y = 18 + ((size.height - 28) * (i / 4));
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), lane);
    }

    // Trophy / medal silhouette
    final cx = size.width / 2;
    final cy = size.height * 0.48;
    final medal = Paint()
      ..color = const Color(0xFFFFE08A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 26, medal);
    canvas.drawCircle(
      Offset(cx, cy),
      20,
      Paint()..color = const Color(0xFFF5C542),
    );
    final ribbon = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 10, cy - 22), Offset(cx - 18, cy - 48), ribbon);
    canvas.drawLine(Offset(cx + 10, cy - 22), Offset(cx + 18, cy - 48), ribbon);

    final star = Paint()..color = const Color(0xFF5A3A00);
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i * 4 * math.pi / 5);
      final p = Offset(cx + math.cos(angle) * 9, cy + math.sin(angle) * 9);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, star);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

IconData _iconFor(String iconName) {
  switch (iconName) {
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

void _openHighlightDetail(BuildContext context, CareerHighlightItem item) {
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
                Icon(_iconFor(item.iconName), color: AppColors.primaryDeep),
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
