import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/video_engine_v2/analysis_results.dart';
import 'race_blueprint_panel.dart';
import 'race_opportunity_meter_panel.dart';

/// Athlete/parent/coach-facing Elite coaching report with clear visuals.
class CoachingReportView extends StatelessWidget {
  const CoachingReportView({
    super.key,
    required this.results,
    required this.athleteName,
    this.onRetry,
    this.retrying = false,
    this.videoUrl,
  });

  final AnalysisResults results;
  final String athleteName;
  final VoidCallback? onRetry;
  final bool retrying;
  /// Optional signed URL so the Race Blueprint can sync phase taps to the clip.
  final String? videoUrl;

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
        RaceBlueprintPanel(
          results: results,
          stroke: stroke,
          recommendations: report.raceRecommendations,
          videoUrl: videoUrl,
        ),
        const SizedBox(height: 16),
        RaceOpportunityMeterPanel(
          report: report,
          stroke: stroke,
          distanceM: int.tryParse(distance ?? ''),
        ),
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
