import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/recruiting/living_passport_payload.dart';
import '../core/theme/app_theme.dart';

/// Public coach/recruiter Living Passport opened via `?lp=` (no login).
///
/// This is intentionally NOT the full athlete dashboard — it is a shareable
/// snapshot designed to strike a coach's eye in one scroll.
class LivingPassportPublicScreen extends StatelessWidget {
  const LivingPassportPublicScreen({super.key, required this.payload});

  final LivingPassportPayload payload;

  static const _factorColors = <String, Color>{
    'cuts': Color(0xFF0B5CAD),
    'depth': Color(0xFF009CFF),
    'progression': Color(0xFF38B6FF),
    'college': Color(0xFF0EA5E9),
    'technique': Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    final piScore = payload.resolvedPowerIndexScore;
    final piLabel = payload.resolvedPowerIndexLabel;
    final generated = _friendlyGenerated(payload.generatedAtIso);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroHeader(payload: payload)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ScoreStrip(
                        swimIqScore: payload.swimIqScore,
                        highestCut: payload.highestCut,
                        readiness: payload.readiness,
                        powerIndexScore: piScore,
                        powerIndexLabel: piLabel,
                      ),
                      const SizedBox(height: 14),
                      if (payload.powerFactors.isNotEmpty) ...[
                        _SectionShell(
                          title: 'Power Index breakdown',
                          subtitle:
                              'What drives this athlete\'s recruiting profile '
                              'right now.',
                          child: _PowerIndexChart(
                            score: piScore,
                            label: piLabel,
                            factors: payload.powerFactors,
                            colors: _factorColors,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _SectionShell(
                        title: 'Signature times',
                        subtitle: payload.strongestEvent != null &&
                                payload.strongestEvent!.trim().isNotEmpty
                            ? 'Strongest signal: ${payload.strongestEvent}'
                            : 'Official bests shared in this snapshot.',
                        child: payload.topTimes.isEmpty
                            ? const Text('No times shared yet.')
                            : _TimesVisualList(times: payload.topTimes),
                      ),
                      const SizedBox(height: 14),
                      _SectionShell(
                        title: 'Meet & focus',
                        subtitle: 'Where attention is pointed this week.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InfoRow(
                              icon: Icons.event_outlined,
                              label: 'Upcoming meet',
                              value: payload.nextMeet,
                            ),
                            if (payload.currentFocus != null &&
                                payload.currentFocus!.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.flag_outlined,
                                label: 'Current focus',
                                value: payload.currentFocus!,
                              ),
                            ],
                            if (payload.usaStandardsSummary != null &&
                                payload.usaStandardsSummary!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.emoji_events_outlined,
                                label: 'USA cuts',
                                value: payload.usaStandardsSummary!,
                              ),
                            ],
                            if (payload.latestClipLabel != null &&
                                payload.latestClipLabel!.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.videocam_outlined,
                                label: 'Latest AI clip',
                                value: payload.latestClipLabel!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionShell(
                        title: 'Technique priorities',
                        subtitle: 'From the latest SwimIQ video analysis.',
                        child: payload.latestTechniquePriorities.isEmpty
                            ? const Text('No video analysis priorities yet.')
                            : _TechniqueList(
                                items: payload.latestTechniquePriorities,
                              ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Coach snapshot · $generated\n'
                        'Refreshes when the athlete regenerates the QR in SwimIQ. '
                        'This is the Living Passport — not the full private app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static String _friendlyGenerated(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso.isEmpty ? 'just now' : iso;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.payload});

  final LivingPassportPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 18,
        20,
        48,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            Color(0xFF0077C8),
            AppColors.primary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SWIMIQ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Living Passport',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            payload.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 34,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Built for coaches & recruiters — score, Power Index, times, '
            'and technique in one scan.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({
    required this.swimIqScore,
    required this.highestCut,
    required this.readiness,
    required this.powerIndexScore,
    required this.powerIndexLabel,
  });

  final int swimIqScore;
  final String highestCut;
  final String readiness;
  final int powerIndexScore;
  final String powerIndexLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          final tiles = [
            _MetricTile(
              label: 'SwimIQ',
              value: swimIqScore > 0 ? '$swimIqScore' : '—',
              hint: 'Activity score',
            ),
            _MetricTile(
              label: 'Power Index',
              value: powerIndexScore > 0 ? '$powerIndexScore' : '—',
              hint: powerIndexLabel,
            ),
            _MetricTile(
              label: 'Highest cut',
              value: highestCut,
              hint: 'USA motivational',
            ),
            _MetricTile(
              label: 'Readiness',
              value: readiness,
              hint: 'Race readiness',
            ),
          ];
          if (wide) {
            return Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: tiles[i]),
                ],
              ],
            );
          }
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tiles
                .map(
                  (t) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: t,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeep,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PowerIndexChart extends StatelessWidget {
  const _PowerIndexChart({
    required this.score,
    required this.label,
    required this.factors,
    required this.colors,
  });

  final int score;
  final String label;
  final List<LivingPassportPowerFactor> factors;
  final Map<String, Color> colors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final chart = SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 52,
                  startDegreeOffset: -90,
                  sections: factors
                      .map(
                        (factor) => PieChartSectionData(
                          value: factor.weightPercent > 0
                              ? factor.weightPercent.toDouble()
                              : 1,
                          color: colors[factor.id] ?? AppColors.accent,
                          title: '${factor.score}',
                          radius: 64,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score > 0 ? '$score' : '—',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final legend = Column(
          children: [
            for (final factor in factors) ...[
              _FactorBar(
                label: factor.label,
                score: factor.score,
                weightPercent: factor.weightPercent,
                color: colors[factor.id] ?? AppColors.accent,
              ),
              const SizedBox(height: 8),
            ],
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: chart),
              const SizedBox(width: 16),
              Expanded(child: legend),
            ],
          );
        }
        return Column(
          children: [
            chart,
            const SizedBox(height: 8),
            legend,
          ],
        );
      },
    );
  }
}

class _FactorBar extends StatelessWidget {
  const _FactorBar({
    required this.label,
    required this.score,
    required this.weightPercent,
    required this.color,
  });

  final String label;
  final int score;
  final int weightPercent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (score.clamp(0, 100)) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Text(
              '$score · ${weightPercent}% wt',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TimesVisualList extends StatelessWidget {
  const _TimesVisualList({required this.times});

  final List<String> times;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < times.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppColors.primaryDeep
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i == 0 ? Colors.white : AppColors.primaryDeep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    times[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.25,
                    ),
                  ),
                ),
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryDeep, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechniqueList extends StatelessWidget {
  const _TechniqueList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
              color: Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryDeep,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
