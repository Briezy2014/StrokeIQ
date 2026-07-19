import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/video_engine_v2/analysis_results.dart';

/// Athlete/parent/coach-facing Elite coaching report with clear visuals.
class CoachingReportView extends StatelessWidget {
  const CoachingReportView({
    super.key,
    required this.results,
    required this.athleteName,
    this.onRetry,
    this.retrying = false,
  });

  final AnalysisResults results;
  final String athleteName;
  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final report = results.report;
    if (report == null) return const SizedBox.shrink();

    final stroke = _strokeLabel(results, report: report);
    final distance = _distanceLabel(results);
    final summary = personalizeSummary(report.summary ?? '', athleteName);
    final raceCue = _friendlyRaceCue(
      _firstRaceCue(report.raceRecommendations),
    );
    final potential = _parsePotentialDrop(report.raceRecommendations);
    final nextRaceLines = _parentCoachRaceLines(
      report.raceRecommendations,
      potential: potential,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        if (results.isFailed) ...[
          _FailureBanner(),
          const SizedBox(height: 14),
        ],
        _ReportHero(
          athleteName: athleteName,
          stroke: stroke,
          distance: distance,
          raceCue: raceCue,
        ),
        if (summary.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            summary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: AppColors.primaryDark,
                ),
          ),
        ],
        const SizedBox(height: 18),
        _RaceFocusMap(
          stroke: stroke,
          recommendations: report.raceRecommendations,
        ),
        const SizedBox(height: 16),
        _StrokeRhythmChart(stroke: stroke),
        if (potential != null) ...[
          const SizedBox(height: 16),
          _PotentialCallout(potential: potential, athleteName: athleteName),
        ],
        if (report.strengths.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionPanel(
            title: 'Keep doing this',
            icon: Icons.thumb_up_alt_outlined,
            accent: const Color(0xFF0F766E),
            children: report.strengths.map(_bullet).toList(),
          ),
        ],
        if (report.priorityImprovements.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionPanel(
            title: 'Fix this next',
            icon: Icons.fitness_center,
            accent: AppColors.primaryDeep,
            children: [
              for (final item in report.priorityImprovements) ...[
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                if (item.drills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dryland',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                  ),
                  const SizedBox(height: 4),
                  ...item.drills.map(_bullet),
                ],
                const SizedBox(height: 12),
              ],
            ],
          ),
        ],
        if (nextRaceLines.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionPanel(
            title: 'Next race',
            icon: Icons.flag_outlined,
            accent: const Color(0xFF1D4ED8),
            children: nextRaceLines.map(_bullet).toList(),
          ),
        ],
        if (results.isFailed && onRetry != null) ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: retrying ? null : onRetry,
            child: Text(retrying ? 'Retrying…' : 'Retry analysis'),
          ),
        ],
      ],
    );
  }

  static String personalizeSummary(String summary, String athleteName) {
    final name = athleteName.trim();
    if (name.isEmpty ||
        name.toLowerCase() == 'demo' ||
        name.toLowerCase() == 'you' ||
        name.toLowerCase() == 'add athlete name') {
      return summary;
    }
    final trimmed = summary.trimLeft();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('you,')) {
      return '$name${trimmed.substring(3)}';
    }
    if (lower.startsWith('you ')) {
      return '$name ${trimmed.substring(4)}';
    }
    return summary;
  }

  static String _strokeLabel(
    AnalysisResults results, {
    AnalysisReport? report,
  }) {
    final fromMap = results.stroke?['stroke'] ?? results.stroke?['type'];
    final raw = (fromMap ??
            results.video?['stroke'] ??
            results.video?['event'] ??
            results.athlete?['stroke'] ??
            '')
        .toString()
        .trim();
    final normalized = _canonicalStroke(raw);
    if (normalized != null) return normalized;

    final inferred = _inferStrokeFromText([
      report?.summary,
      ...?report?.raceRecommendations,
      ...?report?.strengths,
      for (final item in report?.priorityImprovements ?? const []) item.title,
      results.video?['event']?.toString(),
      results.video?['title']?.toString(),
    ]);
    return inferred ?? 'Swim';
  }

  static String? _canonicalStroke(String raw) {
    final lower = raw.toLowerCase().replaceAll('_', ' ').trim();
    if (lower.isEmpty || lower == 'swim' || lower == 'unknown') return null;
    if (lower.contains('butter') || lower.contains('fly')) return 'Butterfly';
    if (lower.contains('back')) return 'Backstroke';
    if (lower.contains('breast')) return 'Breaststroke';
    if (lower.contains('free')) return 'Freestyle';
    if (lower == 'im' ||
        lower.contains('individual medley') ||
        RegExp(r'\bim\b').hasMatch(lower)) {
      return 'IM';
    }
    return null;
  }

  static String? _inferStrokeFromText(List<String?> chunks) {
    for (final chunk in chunks) {
      final hit = _canonicalStroke(chunk ?? '');
      if (hit != null) return hit;
    }
    return null;
  }

  static String? _distanceLabel(AnalysisResults results) {
    final d = results.stroke?['distance_m'] ??
        results.video?['distance_m'] ??
        results.athlete?['distance_m'];
    if (d is num && d > 0) return '${d.toInt()}';
    final parsed = int.tryParse('$d');
    if (parsed != null && parsed > 0) return '$parsed';
    return null;
  }

  static String? _firstRaceCue(List<String> lines) {
    for (final line in lines) {
      final t = line.trim();
      if (t.toLowerCase().startsWith('race cue')) return t;
    }
    return lines.isNotEmpty ? lines.first.trim() : null;
  }

  /// Keep race cues short and parent/coach friendly.
  static String? _friendlyRaceCue(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // Drop technical metric chatter if a model ever appends it.
    text = text
        .replaceAll(
          RegExp(
            r'\b(swimmer visibility|frames analyzed|coverage fraction)\b.*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (!text.toLowerCase().startsWith('race cue')) {
      text = 'Race cue: $text';
    }
    return text;
  }

  static ({String low, String high})? _parsePotentialDrop(List<String> lines) {
    final patterns = [
      RegExp(
        r'(\d+(?:\.\d+)?)\s*[-–—]\s*(\d+(?:\.\d+)?)\s*(?:sec(?:onds?)?)?',
        caseSensitive: false,
      ),
    ];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!(lower.contains('potential') ||
          lower.contains('drop') ||
          lower.contains('faster') ||
          lower.contains('sec'))) {
        continue;
      }
      for (final re in patterns) {
        final m = re.firstMatch(line);
        if (m != null) {
          return (low: m.group(1)!, high: m.group(2)!);
        }
      }
    }
    return null;
  }

  static List<String> _parentCoachRaceLines(
    List<String> lines, {
    ({String low, String high})? potential,
  }) {
    final cleaned = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final lower = t.toLowerCase();
      if (lower.contains('swimmer visibility') ||
          lower.contains('frames analyzed') ||
          lower.contains('coverage fraction') ||
          lower.contains('frames with swimmer')) {
        continue;
      }
      // Potential is shown in its own callout.
      if (potential != null &&
          (lower.contains('potential') ||
              RegExp(r'\d+(?:\.\d+)?\s*[-–—]\s*\d+(?:\.\d+)?\s*sec')
                  .hasMatch(lower))) {
        continue;
      }
      cleaned.add(t);
    }
    return cleaned;
  }

  static Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(
              child: Text(text, style: const TextStyle(height: 1.35)),
            ),
          ],
        ),
      );
}

class _FailureBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC2410C)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'We could not finish a full coaching report for this clip. '
                'Try again with a clear side-view video of the whole race.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportHero extends StatelessWidget {
  const _ReportHero({
    required this.athleteName,
    required this.stroke,
    required this.distance,
    required this.raceCue,
  });

  final String athleteName;
  final String stroke;
  final String? distance;
  final String? raceCue;

  @override
  Widget build(BuildContext context) {
    final eventLine = [
      if (distance != null) distance!,
      stroke,
    ].join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF041526),
            Color(0xFF0B3D6E),
            AppColors.primaryDeep,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COACHING REPORT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            athleteName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            eventLine,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (raceCue != null && raceCue!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bolt,
                    size: 18,
                    color: AppColors.accent.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      raceCue!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
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

class _RaceFocusMap extends StatelessWidget {
  const _RaceFocusMap({
    required this.stroke,
    required this.recommendations,
  });

  final String stroke;
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    final phases = _phasesFor(stroke, recommendations);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Race focus map',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Where to put attention from start to wall.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final tiles = [
                for (final p in phases)
                  _FocusPhaseTile(label: p.label, cue: p.cue, icon: p.icon),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tiles
                    .map(
                      (t) => SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: t,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<({String label, String cue, IconData icon})> _phasesFor(
    String stroke,
    List<String> recommendations,
  ) {
    final joined = recommendations.join(' ').toLowerCase();
    final isFly = stroke.toLowerCase().contains('butter');
    final isFree = stroke.toLowerCase().contains('free');
    final isBack = stroke.toLowerCase().contains('back');
    final isBreast = stroke.toLowerCase().contains('breast');

    String uw = 'Tight underwater dolphins';
    String breakout = 'Break out on tempo';
    String mid = 'Hold body line';
    String finish = 'Finish strong & long';

    if (joined.contains('underwater')) {
      uw = 'Tight underwater first';
    }
    if (joined.contains('kick on entry') || joined.contains('kick-on-entry')) {
      mid = 'Kick on entry';
    }
    if (joined.contains('breathe late')) {
      mid = isFly ? 'Kick on entry · breathe late' : 'Breathe late & quiet';
    }
    if (joined.contains('early catch')) {
      mid = 'Early catch pressure';
    }
    if (joined.contains('hips')) {
      mid = 'Hips up · press the chest';
    }
    if (isFree) {
      breakout = 'Quiet head into stroke';
      finish = 'Kick does not stop';
    } else if (isBack) {
      uw = 'Streamline + dolphin';
      mid = 'Hips up · clean entry';
    } else if (isBreast) {
      uw = 'Pullout timing';
      mid = 'Shoot & glide long';
      finish = 'Quick turn into walls';
    } else if (isFly) {
      breakout = 'Tempo you can hold';
      finish = 'Kick through the touch';
    }

    return [
      (label: 'Start / UW', cue: uw, icon: Icons.waves),
      (label: 'Breakout', cue: breakout, icon: Icons.trending_up),
      (label: 'Mid-race', cue: mid, icon: Icons.timeline),
      (label: 'Finish', cue: finish, icon: Icons.flag),
    ];
  }
}

class _FocusPhaseTile extends StatelessWidget {
  const _FocusPhaseTile({
    required this.label,
    required this.cue,
    required this.icon,
  });

  final String label;
  final String cue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDeep),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cue,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.25,
              color: AppColors.textDark.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokeRhythmChart extends StatelessWidget {
  const _StrokeRhythmChart({required this.stroke});

  final String stroke;

  @override
  Widget build(BuildContext context) {
    final guide = _guideFor(stroke);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stroke rhythm guide',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            guide.caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark.withValues(alpha: 0.72),
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 1,
                minY: 0,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) {
                        final labels = guide.xLabels;
                        final key = value.toStringAsFixed(2);
                        final label = labels[key];
                        if (label == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: guide.spots,
                    isCurved: true,
                    color: AppColors.primaryDeep,
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final highlight = guide.highlightIndexes.contains(index);
                        return FlDotCirclePainter(
                          radius: highlight ? 5.5 : 3.2,
                          color: highlight
                              ? AppColors.accent
                              : AppColors.primaryDeep,
                          strokeWidth: highlight ? 2 : 0,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            guide.footer,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
          ),
        ],
      ),
    );
  }

  _RhythmGuide _guideFor(String stroke) {
    final s = stroke.toLowerCase();
    if (s.contains('butter') || (s.contains('fly') && !s.contains('free'))) {
      return _RhythmGuide(
        caption:
            'Butterfly rhythm model for parents & coaches — timing cue only, not a live sensor trace. '
            'Chase the second kick with the hands.',
        footer: 'Highlight: second kick on hand entry · breathe late and low',
        highlightIndexes: const {3},
        spots: const [
          FlSpot(0, 0.35),
          FlSpot(0.18, 0.88),
          FlSpot(0.38, 0.48),
          FlSpot(0.58, 0.86),
          FlSpot(0.78, 0.42),
          FlSpot(1, 0.35),
        ],
        xLabels: const {
          '0.00': 'Entry',
          '0.25': 'Pull',
          '0.50': 'Kick 2',
          '0.75': 'Recover',
          '1.00': 'Entry',
        },
      );
    }
    if (s.contains('breast')) {
      return _RhythmGuide(
        caption:
            'Breaststroke rhythm model for parents & coaches — pull, breathe, kick, glide.',
        footer: 'Highlight: long glide before the next pull',
        highlightIndexes: const {4},
        spots: const [
          FlSpot(0, 0.55),
          FlSpot(0.2, 0.85),
          FlSpot(0.4, 0.7),
          FlSpot(0.55, 0.9),
          FlSpot(0.8, 0.4),
          FlSpot(1, 0.55),
        ],
        xLabels: const {
          '0.00': 'Pull',
          '0.25': 'Breath',
          '0.50': 'Kick',
          '0.75': 'Glide',
          '1.00': 'Pull',
        },
      );
    }
    if (s.contains('back')) {
      return _RhythmGuide(
        caption:
            'Backstroke rhythm model for parents & coaches — hips high and a clean hand entry.',
        footer: 'Highlight: hand entry with hips up',
        highlightIndexes: const {1, 4},
        spots: const [
          FlSpot(0, 0.55),
          FlSpot(0.2, 0.8),
          FlSpot(0.4, 0.5),
          FlSpot(0.6, 0.78),
          FlSpot(0.8, 0.48),
          FlSpot(1, 0.55),
        ],
        xLabels: const {
          '0.00': 'Entry',
          '0.25': 'Catch',
          '0.50': 'Pull',
          '0.75': 'Recover',
          '1.00': 'Entry',
        },
      );
    }
    if (s == 'im' || s.contains('medley')) {
      return _RhythmGuide(
        caption:
            'IM rhythm model for parents & coaches — clean transitions keep speed between strokes.',
        footer: 'Highlight: tight transition, then settle into tempo',
        highlightIndexes: const {2},
        spots: const [
          FlSpot(0, 0.45),
          FlSpot(0.25, 0.8),
          FlSpot(0.5, 0.55),
          FlSpot(0.75, 0.82),
          FlSpot(1, 0.45),
        ],
        xLabels: const {
          '0.00': 'Fly',
          '0.25': 'Back',
          '0.50': 'Breast',
          '0.75': 'Free',
          '1.00': 'Wall',
        },
      );
    }
    // freestyle / default only when stroke is actually freestyle or unknown
    return _RhythmGuide(
      caption: s.contains('free')
          ? 'Freestyle rhythm model for parents & coaches — quiet head and early catch pressure.'
          : 'Stroke rhythm model for parents & coaches — one timing cue to practice this week.',
      footer: s.contains('free')
          ? 'Highlight: early catch before the pull'
          : 'Highlight: one timing cue — keep it simple in the race',
      highlightIndexes: const {1},
      spots: const [
        FlSpot(0, 0.5),
        FlSpot(0.18, 0.82),
        FlSpot(0.4, 0.55),
        FlSpot(0.62, 0.8),
        FlSpot(0.82, 0.48),
        FlSpot(1, 0.5),
      ],
      xLabels: const {
        '0.00': 'Entry',
        '0.25': 'Catch',
        '0.50': 'Pull',
        '0.75': 'Recover',
        '1.00': 'Entry',
      },
    );
  }
}

class _RhythmGuide {
  const _RhythmGuide({
    required this.caption,
    required this.footer,
    required this.spots,
    required this.xLabels,
    required this.highlightIndexes,
  });

  final String caption;
  final String footer;
  final List<FlSpot> spots;
  final Map<String, String> xLabels;
  final Set<int> highlightIndexes;
}

class _PotentialCallout extends StatelessWidget {
  const _PotentialCallout({
    required this.potential,
    required this.athleteName,
  });

  final ({String low, String high}) potential;
  final String athleteName;

  @override
  Widget build(BuildContext context) {
    final hasName = athleteName.trim().isNotEmpty &&
        athleteName.toLowerCase() != 'demo' &&
        athleteName.toLowerCase() != 'add athlete name' &&
        athleteName.toLowerCase() != 'you';
    final who = hasName ? athleteName.trim() : 'this swimmer';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${potential.low}–${potential.high}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'sec drop',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "That's about a ${potential.low}–${potential.high} second drop for $who "
              'with this race focus — practice the cue in training, then race it.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: AppColors.primaryDark,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
