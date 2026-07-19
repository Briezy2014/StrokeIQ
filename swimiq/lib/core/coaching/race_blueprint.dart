import '../../data/models/video_engine_v2/analysis_metric.dart';
import '../../data/models/video_engine_v2/analysis_results.dart';

/// One race segment on the Race Blueprint energy curve.
class RaceBlueprintPhase {
  const RaceBlueprintPhase({
    required this.id,
    required this.label,
    required this.cue,
    required this.startFraction,
    required this.endFraction,
    this.seekMs,
    this.measured = false,
  });

  final String id;
  final String label;
  final String cue;
  /// Normalized 0–1 position along the race / clip.
  final double startFraction;
  final double endFraction;
  final int? seekMs;
  final bool measured;

  double get midFraction => ((startFraction + endFraction) / 2).clamp(0.0, 1.0);
}

/// Parent/coach-friendly race map: effort from start → wall for THIS clip.
class RaceBlueprint {
  const RaceBlueprint({
    required this.caption,
    required this.footer,
    required this.phases,
    required this.energyPoints,
    required this.durationMs,
    required this.usesMeasuredTiming,
    required this.finishFades,
  });

  final String caption;
  final String footer;
  final List<RaceBlueprintPhase> phases;
  /// Effort samples as (fractionAlongRace, effort 0–1).
  final List<({double x, double y})> energyPoints;
  final int? durationMs;
  final bool usesMeasuredTiming;
  final bool finishFades;

  /// Seek ms for a normalized playhead, or null when duration unknown.
  int? seekMsForFraction(double fraction) {
    final duration = durationMs;
    if (duration == null || duration <= 0) return null;
    return (fraction.clamp(0.0, 1.0) * duration).round();
  }

  double fractionForMs(int ms) {
    final duration = durationMs;
    if (duration == null || duration <= 0) return 0;
    return (ms / duration).clamp(0.0, 1.0);
  }
}

/// Builds a Race Blueprint from Elite analysis + coaching copy.
class RaceBlueprintBuilder {
  const RaceBlueprintBuilder._();

  static RaceBlueprint fromResults({
    required AnalysisResults results,
    required String stroke,
    required List<String> recommendations,
  }) {
    final durationMs = _durationMs(results);
    final cues = _phaseCues(stroke, recommendations);
    final finishFades = _finishFades(results.metrics, recommendations);
    final phases = _buildPhases(
      results: results,
      cues: cues,
      durationMs: durationMs,
    );
    final energyPoints = _energyCurve(
      stroke: stroke,
      phases: phases,
      finishFades: finishFades,
      distanceM: _distanceM(results),
    );
    final measured = phases.any((p) => p.measured);
    final footer = _footer(cues, finishFades: finishFades);
    final caption = measured
        ? 'Effort map for this race — phases use timing from your clip. '
            'Tap a phase to jump in the video.'
        : 'Effort map for this race — start to wall coaching guide for parents & coaches. '
            'Tap a phase to jump in the video when playback is ready.';

    return RaceBlueprint(
      caption: caption,
      footer: footer,
      phases: phases,
      energyPoints: energyPoints,
      durationMs: durationMs,
      usesMeasuredTiming: measured,
      finishFades: finishFades,
    );
  }

  static int? _durationMs(AnalysisResults results) {
    final video = results.video;
    if (video != null) {
      for (final key in ['duration_ms', 'durationMs', 'duration']) {
        final raw = video[key];
        if (raw is num && raw > 0) {
          // duration may already be ms, or seconds if small.
          if (key == 'duration' && raw < 1000) {
            return (raw * 1000).round();
          }
          return raw.round();
        }
      }
    }
    var maxEnd = 0;
    for (final phase in results.phases) {
      final end = phase.endMs ?? phase.startMs;
      if (end != null && end > maxEnd) maxEnd = end;
    }
    for (final metric in results.metrics) {
      final end = metric.endMs ?? metric.startMs;
      if (end != null && end > maxEnd) maxEnd = end;
    }
    if (maxEnd > 0) return maxEnd;
    return null;
  }

  static int? _distanceM(AnalysisResults results) {
    final d = results.stroke?['distance_m'] ??
        results.video?['distance_m'] ??
        results.athlete?['distance_m'];
    if (d is num && d > 0) return d.round();
    return int.tryParse('$d');
  }

  static bool _finishFades(
    List<AnalysisMetric> metrics,
    List<String> recommendations,
  ) {
    for (final m in metrics) {
      final name = m.name.toLowerCase();
      if (m.value == null) continue;
      if (name.contains('late_clip_stroke_rate') ||
          name.contains('stroke_rate_change') ||
          name.contains('tempo_change')) {
        if (m.value! < -0.5) return true;
      }
    }
    final joined = recommendations.join(' ').toLowerCase();
    return joined.contains('fade') ||
        joined.contains('dies late') ||
        joined.contains('tempo drops') ||
        joined.contains('slowing late');
  }

  static ({String uw, String breakout, String mid, String finish}) _phaseCues(
    String stroke,
    List<String> recommendations,
  ) {
    final joined = recommendations.join(' ').toLowerCase();
    final isFly = stroke.toLowerCase().contains('butter') ||
        (stroke.toLowerCase().contains('fly') &&
            !stroke.toLowerCase().contains('free'));
    final isFree = stroke.toLowerCase().contains('free');
    final isBack = stroke.toLowerCase().contains('back');
    final isBreast = stroke.toLowerCase().contains('breast');

    var uw = 'Tight underwater first';
    var breakout = 'Break out on tempo';
    var mid = 'Hold body line';
    var finish = 'Finish strong & long';

    if (joined.contains('underwater')) uw = 'Tight underwater first';
    if (joined.contains('kick on entry') || joined.contains('kick-on-entry')) {
      mid = 'Kick on entry';
    }
    if (joined.contains('breathe late')) {
      mid = isFly ? 'Kick on entry · breathe late' : 'Breathe late & quiet';
    }
    if (joined.contains('early catch')) mid = 'Early catch pressure';
    if (joined.contains('hips')) mid = 'Hips up · press the chest';

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

    return (uw: uw, breakout: breakout, mid: mid, finish: finish);
  }

  static List<RaceBlueprintPhase> _buildPhases({
    required AnalysisResults results,
    required ({String uw, String breakout, String mid, String finish}) cues,
    required int? durationMs,
  }) {
    final underwater = _firstPhaseMatching(results.phases, const [
      'underwater',
      'uw',
    ]);
    final duration = durationMs ?? _guessDurationFromPhases(results.phases);

    if (underwater != null &&
        underwater.startMs != null &&
        underwater.endMs != null &&
        duration != null &&
        duration > 0) {
      final uwStartFrac =
          (underwater.startMs! / duration).clamp(0.0, 0.35);
      final uwEnd =
          (underwater.endMs! / duration).clamp(uwStartFrac + 0.05, 0.45);
      final breakoutEnd = (uwEnd + 0.12).clamp(uwEnd + 0.05, 0.55);
      return [
        RaceBlueprintPhase(
          id: 'start_uw',
          label: 'Start / UW',
          cue: cues.uw,
          startFraction: 0,
          endFraction: uwEnd,
          seekMs: underwater.startMs,
          measured: true,
        ),
        RaceBlueprintPhase(
          id: 'breakout',
          label: 'Breakout',
          cue: cues.breakout,
          startFraction: uwEnd,
          endFraction: breakoutEnd,
          seekMs: underwater.endMs,
          measured: true,
        ),
        RaceBlueprintPhase(
          id: 'mid',
          label: 'Mid-race',
          cue: cues.mid,
          startFraction: breakoutEnd,
          endFraction: 0.82,
          seekMs: ((breakoutEnd + 0.82) / 2 * duration).round(),
        ),
        RaceBlueprintPhase(
          id: 'finish',
          label: 'Finish',
          cue: cues.finish,
          startFraction: 0.82,
          endFraction: 1,
          seekMs: (0.85 * duration).round(),
        ),
      ];
    }

    // Default race fractions — clear start-to-wall blueprint.
    return [
      RaceBlueprintPhase(
        id: 'start_uw',
        label: 'Start / UW',
        cue: cues.uw,
        startFraction: 0,
        endFraction: 0.18,
        seekMs: duration == null ? null : 0,
      ),
      RaceBlueprintPhase(
        id: 'breakout',
        label: 'Breakout',
        cue: cues.breakout,
        startFraction: 0.18,
        endFraction: 0.34,
        seekMs: duration == null ? null : (0.22 * duration).round(),
      ),
      RaceBlueprintPhase(
        id: 'mid',
        label: 'Mid-race',
        cue: cues.mid,
        startFraction: 0.34,
        endFraction: 0.78,
        seekMs: duration == null ? null : (0.55 * duration).round(),
      ),
      RaceBlueprintPhase(
        id: 'finish',
        label: 'Finish',
        cue: cues.finish,
        startFraction: 0.78,
        endFraction: 1,
        seekMs: duration == null ? null : (0.86 * duration).round(),
      ),
    ];
  }

  static AnalysisPhase? _firstPhaseMatching(
    List<AnalysisPhase> phases,
    List<String> needles,
  ) {
    for (final phase in phases) {
      final name = phase.name.toLowerCase();
      for (final needle in needles) {
        if (name.contains(needle)) return phase;
      }
    }
    return null;
  }

  static int? _guessDurationFromPhases(List<AnalysisPhase> phases) {
    var maxEnd = 0;
    for (final phase in phases) {
      final end = phase.endMs ?? phase.startMs;
      if (end != null && end > maxEnd) maxEnd = end;
    }
    return maxEnd > 0 ? maxEnd : null;
  }

  static List<({double x, double y})> _energyCurve({
    required String stroke,
    required List<RaceBlueprintPhase> phases,
    required bool finishFades,
    required int? distanceM,
  }) {
    final sprint = (distanceM ?? 50) <= 50;
    final isFly = stroke.toLowerCase().contains('butter') ||
        (stroke.toLowerCase().contains('fly') &&
            !stroke.toLowerCase().contains('free'));
    final isBreast = stroke.toLowerCase().contains('breast');

    // Effort shape parents can read: explode off the wall, settle, finish.
    var start = sprint ? 0.92 : 0.78;
    var breakout = sprint ? 0.86 : 0.72;
    var mid = sprint ? 0.68 : 0.62;
    var late = sprint ? 0.74 : 0.66;
    var finish = sprint ? 0.88 : 0.72;

    if (isFly) {
      mid = sprint ? 0.64 : 0.58;
      late = finishFades ? 0.48 : 0.70;
      finish = finishFades ? 0.42 : 0.86;
    } else if (isBreast) {
      start = 0.80;
      mid = 0.58;
      finish = finishFades ? 0.46 : 0.78;
    } else if (finishFades) {
      late = 0.50;
      finish = 0.44;
    }

    // Anchor samples to phase midpoints so the curve "syncs" visually.
    final byId = {for (final p in phases) p.id: p};
    final uw = byId['start_uw'];
    final bo = byId['breakout'];
    final midP = byId['mid'];
    final fin = byId['finish'];

    return [
      (x: 0.0, y: start * 0.82),
      (x: uw?.midFraction ?? 0.09, y: start),
      (x: bo?.midFraction ?? 0.26, y: breakout),
      (x: midP?.startFraction ?? 0.40, y: mid),
      (x: midP?.midFraction ?? 0.56, y: mid * 0.96),
      (x: midP?.endFraction ?? 0.76, y: late),
      (x: fin?.midFraction ?? 0.90, y: finish),
      (x: 1.0, y: (finish * 0.92).clamp(0.2, 1.0)),
    ];
  }

  static String _footer(
    ({String uw, String breakout, String mid, String finish}) cues, {
    required bool finishFades,
  }) {
    if (finishFades) {
      return 'Watch the finish: energy dips late — protect tempo into the wall.';
    }
    return 'Key focus: ${cues.mid} · Finish: ${cues.finish}';
  }
}
