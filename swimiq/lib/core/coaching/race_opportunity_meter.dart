import '../../data/models/video_engine_v2/analysis_results.dart';

/// Green / yellow / red coaching signal for one race segment.
enum OpportunitySignal {
  lockedIn,
  watch,
  opportunity,
}

/// One clickable row on the Opportunity Meter / Race Scan.
class OpportunitySegment {
  const OpportunitySegment({
    required this.id,
    required this.label,
    required this.signal,
    required this.whatHappened,
    required this.nextRaceCue,
    this.opportunityLowSec,
    this.opportunityHighSec,
    this.swimDrills = const [],
    this.drylandDrills = const [],
    this.mentionedByAnalysis = false,
  });

  final String id;
  final String label;
  final OpportunitySignal signal;
  final String whatHappened;
  final String nextRaceCue;
  /// Coaching estimate of time still available in this segment (seconds).
  final double? opportunityLowSec;
  final double? opportunityHighSec;
  final List<String> swimDrills;
  final List<String> drylandDrills;
  final bool mentionedByAnalysis;

  String get opportunityLabel {
    if (signal == OpportunitySignal.lockedIn ||
        opportunityLowSec == null ||
        opportunityHighSec == null) {
      return 'Locked in';
    }
    final low = _fmt(opportunityLowSec!);
    final high = _fmt(opportunityHighSec!);
    if (low == high) return '~$low s';
    return '~$low–$high s';
  }

  static String _fmt(double v) {
    if ((v * 100).round() % 10 == 0) {
      return v.toStringAsFixed(1);
    }
    return v.toStringAsFixed(2);
  }
}

/// How this Race Scan was produced for the customer.
enum RaceScanMode {
  /// Phone-friendly coaching from this clip — always available at launch.
  phoneCoaching,

  /// Pose / UW / turn / finish sensors enriched parts of the scan.
  sensorBoosted,
}

/// Opportunity Meter™ / Race Scan built from Elite coaching analysis.
class RaceOpportunityMeter {
  const RaceOpportunityMeter({
    required this.segments,
    required this.raceIq,
    required this.caption,
    required this.mode,
    this.potentialLowSec,
    this.potentialHighSec,
  });

  final List<OpportunitySegment> segments;
  final int raceIq;
  final String caption;
  final RaceScanMode mode;
  final double? potentialLowSec;
  final double? potentialHighSec;

  String get modeBadge => mode == RaceScanMode.sensorBoosted
      ? 'Sensor boosted'
      : 'Phone coaching';

  String get modeSubtitle => mode == RaceScanMode.sensorBoosted
      ? 'Extra body-line / race timing locked from this clip where the camera allowed it.'
      : 'Built for phone race videos — body line, breathing, and tempo cues even when angles aren’t perfect.';

  String get potentialLabel {
    if (potentialLowSec == null || potentialHighSec == null) {
      return 'Build your next drop';
    }
    final low = OpportunitySegment._fmt(potentialLowSec!);
    final high = OpportunitySegment._fmt(potentialHighSec!);
    return low == high ? '$low sec' : '$low–$high sec';
  }

  bool get hasPotential =>
      potentialLowSec != null && potentialHighSec != null;
}

/// Maps AI coaching copy → addictive, honest Race Scan rows.
///
/// Does **not** invent fake sensor hundredths. Opportunity seconds are
/// coaching estimates allocated from the report's potential-drop range.
class RaceOpportunityMeterBuilder {
  const RaceOpportunityMeterBuilder._();

  static RaceOpportunityMeter fromReport({
    required AnalysisReport report,
    required String stroke,
    int? distanceM,
    AnalysisResults? results,
  }) {
    final corpus = _Corpus.fromReport(report);
    final potential = _parsePotential(report.raceRecommendations);
    final ids = _segmentIdsFor(stroke: stroke, distanceM: distanceM);
    final mode = modeFor(results);

    final scored = <_ScoredSegment>[];
    for (final id in ids) {
      scored.add(_scoreSegment(id: id, corpus: corpus, stroke: stroke));
    }

    final allocated = _allocateOpportunity(scored, potential);
    final raceIq = _raceIq(allocated);
    final caption = mode == RaceScanMode.sensorBoosted
        ? 'Where time can still be found — tap a row for the cue and drills. '
            'Green rows look solid; yellow/red still have time on the table.'
        : 'Where time can still be found on this phone race video — tap a row '
            'for the cue and drills. Perfect camera angles not required.';

    return RaceOpportunityMeter(
      segments: allocated,
      raceIq: raceIq,
      caption: caption,
      mode: mode,
      potentialLowSec: potential?.low,
      potentialHighSec: potential?.high,
    );
  }

  /// Detect whether Elite sensors enriched this job (pose soft-fail → phone mode).
  static RaceScanMode modeFor(AnalysisResults? results) {
    if (results == null) return RaceScanMode.phoneCoaching;

    for (final phase in results.phases) {
      final name = phase.name.toLowerCase();
      if (name.contains('underwater') ||
          name.contains('turn') ||
          name.contains('finish') ||
          name.contains('butterfly')) {
        return RaceScanMode.sensorBoosted;
      }
    }

    final tracking = results.tracking;
    if (tracking != null) {
      for (final key in const [
        'pose',
        'butterfly',
        'underwater',
        'turn',
        'finish',
      ]) {
        final value = tracking[key];
        if (value is! Map || value.isEmpty) continue;
        if (key == 'pose' &&
            (value['status']?.toString().toLowerCase() == 'skipped')) {
          continue;
        }
        return RaceScanMode.sensorBoosted;
      }
    }

    for (final metric in results.metrics) {
      if (metric.isUnavailable) continue;
      final name = metric.name.toLowerCase();
      if (name.contains('underwater') ||
          name.contains('stroke_rate') ||
          name.contains('breakout') ||
          name.contains('turn') ||
          name.contains('finish')) {
        return RaceScanMode.sensorBoosted;
      }
    }

    return RaceScanMode.phoneCoaching;
  }

  static List<String> _segmentIdsFor({
    required String stroke,
    int? distanceM,
  }) {
    final distance = distanceM ?? 50;
    final includeTurns = distance >= 100;
    final s = stroke.toLowerCase();
    final isBreast = s.contains('breast');

    return [
      'reaction',
      if (!isBreast) 'underwater' else 'pullout',
      'breakout',
      'tempo',
      'breathing',
      if (includeTurns) 'turns',
      'finish',
    ];
  }

  static _ScoredSegment _scoreSegment({
    required String id,
    required _Corpus corpus,
    required String stroke,
  }) {
    final keys = _keywordsFor(id);
    final hitImprovement = corpus.bestImprovement(keys);
    final hitRace = corpus.bestRaceLine(keys);
    final hitStrength = corpus.bestStrength(keys);
    final mentioned = hitImprovement != null || hitRace != null;

    OpportunitySignal signal;
    if (hitImprovement != null) {
      signal = OpportunitySignal.opportunity;
    } else if (hitRace != null && hitStrength == null) {
      signal = OpportunitySignal.watch;
    } else {
      signal = OpportunitySignal.lockedIn;
    }

    final drills = hitImprovement?.drills ?? const <String>[];
    final dryland = <String>[];
    final swim = <String>[];
    for (final d in drills) {
      final lower = d.toLowerCase();
      if (lower.contains('dryland') ||
          lower.contains('band') ||
          lower.contains('plank') ||
          lower.contains('hollow') ||
          lower.contains('bridge') ||
          lower.contains('jump-rope') ||
          lower.contains('wall angel') ||
          lower.contains('dead-bug')) {
        dryland.add(d);
      } else if (lower.contains('swim') ||
          lower.contains('kickboard') ||
          lower.contains('25') ||
          lower.contains('50') ||
          lower.contains('drill:')) {
        swim.add(d);
      } else {
        dryland.add(d);
      }
    }
    if (swim.isEmpty && signal != OpportunitySignal.lockedIn) {
      swim.add(_defaultSwimDrill(id, stroke));
    }

    return _ScoredSegment(
      id: id,
      label: _labelFor(id),
      signal: signal,
      whatHappened: hitImprovement?.title ??
          hitRace ??
          hitStrength ??
          _defaultLockedCopy(id),
      nextRaceCue: _nextCue(
        id: id,
        improvement: hitImprovement?.title,
        raceLine: hitRace,
        stroke: stroke,
      ),
      swimDrills: swim,
      drylandDrills: dryland,
      mentionedByAnalysis: mentioned,
      weight: signal == OpportunitySignal.opportunity
          ? 3
          : signal == OpportunitySignal.watch
              ? 1
              : 0,
    );
  }

  static List<OpportunitySegment> _allocateOpportunity(
    List<_ScoredSegment> scored,
    ({double low, double high})? potential,
  ) {
    final totalWeight =
        scored.fold<int>(0, (sum, s) => sum + s.weight).clamp(1, 999);
    return [
      for (final s in scored)
        OpportunitySegment(
          id: s.id,
          label: s.label,
          signal: s.signal,
          whatHappened: s.whatHappened,
          nextRaceCue: s.nextRaceCue,
          opportunityLowSec: potential == null || s.weight == 0
              ? null
              : potential.low * s.weight / totalWeight,
          opportunityHighSec: potential == null || s.weight == 0
              ? null
              : potential.high * s.weight / totalWeight,
          swimDrills: s.swimDrills,
          drylandDrills: s.drylandDrills,
          mentionedByAnalysis: s.mentionedByAnalysis,
        ),
    ];
  }

  static int _raceIq(List<OpportunitySegment> segments) {
    if (segments.isEmpty) return 80;
    var score = 0.0;
    for (final s in segments) {
      switch (s.signal) {
        case OpportunitySignal.lockedIn:
          score += 100;
        case OpportunitySignal.watch:
          score += 78;
        case OpportunitySignal.opportunity:
          score += 52;
      }
    }
    return (score / segments.length).round().clamp(40, 99);
  }

  static ({double low, double high})? _parsePotential(List<String> lines) {
    final re = RegExp(
      r'(\d+(?:\.\d+)?)\s*[-–—]\s*(\d+(?:\.\d+)?)\s*(?:sec(?:onds?)?)?',
      caseSensitive: false,
    );
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!(lower.contains('potential') ||
          lower.contains('drop') ||
          lower.contains('faster') ||
          lower.contains('sec'))) {
        continue;
      }
      final m = re.firstMatch(line);
      if (m == null) continue;
      final low = double.tryParse(m.group(1)!);
      final high = double.tryParse(m.group(2)!);
      if (low == null || high == null) continue;
      return (low: low, high: high);
    }
    return null;
  }

  static List<String> _keywordsFor(String id) {
    switch (id) {
      case 'reaction':
        return const ['reaction', 'dive', 'start block', 'takeoff', 'start /'];
      case 'underwater':
        return const [
          'underwater',
          'dolphin',
          'streamline',
          'first 15',
          '15m',
        ];
      case 'pullout':
        return const ['pullout', 'pull-out', 'underwater', 'streamline'];
      case 'breakout':
        return const ['breakout', 'break out', 'surface'];
      case 'tempo':
        return const [
          'tempo',
          'stroke rate',
          'rhythm',
          'kick on entry',
          'second kick',
          'catch',
          'stroke timing',
        ];
      case 'breathing':
        return const [
          'breath',
          'breathe',
          'breathing',
          'head lift',
          'hips drop',
          'press the chest',
          'quiet head',
        ];
      case 'turns':
        return const ['turn', 'wall', 'flip', 'open turn'];
      case 'finish':
        return const ['finish', 'touch', 'last 5', 'last 10', 'into the wall'];
      default:
        return const [];
    }
  }

  static String _labelFor(String id) {
    switch (id) {
      case 'reaction':
        return 'Reaction';
      case 'underwater':
        return 'Underwater';
      case 'pullout':
        return 'Pullout';
      case 'breakout':
        return 'Breakout';
      case 'tempo':
        return 'Tempo';
      case 'breathing':
        return 'Breathing';
      case 'turns':
        return 'Turns';
      case 'finish':
        return 'Finish';
      default:
        return id;
    }
  }

  static String _defaultLockedCopy(String id) {
    switch (id) {
      case 'reaction':
        return 'Start looked race-ready on this clip.';
      case 'underwater':
        return 'Underwater work looks like a keep-doing-this piece.';
      case 'pullout':
        return 'Pullout timing looks solid on this race.';
      case 'breakout':
        return 'Breakout looks connected into stroke.';
      case 'tempo':
        return 'Tempo looks controlled enough to race.';
      case 'breathing':
        return 'Breathing pattern did not stand out as a time thief.';
      case 'turns':
        return 'Turns were not flagged as a big opportunity here.';
      case 'finish':
        return 'Finish commitment looks strong.';
      default:
        return 'No major opportunity flagged in this segment.';
    }
  }

  static String _nextCue({
    required String id,
    required String? improvement,
    required String? raceLine,
    required String stroke,
  }) {
    if (improvement != null && improvement.trim().isNotEmpty) {
      return 'Next race: ${improvement.trim()}';
    }
    if (raceLine != null && raceLine.trim().isNotEmpty) {
      return raceLine.trim();
    }
    switch (id) {
      case 'breathing':
        return stroke.toLowerCase().contains('butter')
            ? 'Next race: breathe late and low — keep hips up.'
            : 'Next race: quiet head, one clean breath pattern.';
      case 'tempo':
        return 'Next race: hold the same tempo you can finish with.';
      case 'finish':
        return 'Next race: long last stroke — kick through the touch.';
      default:
        return 'Next race: keep this segment simple and automatic.';
    }
  }

  static String _defaultSwimDrill(String id, String stroke) {
    final fly = stroke.toLowerCase().contains('butter');
    switch (id) {
      case 'reaction':
        return 'Swim: 6× dive + 3 underwater kicks, hold streamline to the flags.';
      case 'underwater':
        return 'Swim: 8× 15m underwater dolphin, easy swim back.';
      case 'pullout':
        return 'Swim: 6× breast pullouts — count the glide before the first stroke.';
      case 'breakout':
        return 'Swim: 6× breakout 25s — first 3 strokes at race tempo.';
      case 'tempo':
        return fly
            ? 'Swim: 8× 25 fly kick-on-entry focus, easy 25 back.'
            : 'Swim: 8× 25 race-tempo, count strokes, hold the same count.';
      case 'breathing':
        return fly
            ? 'Swim: 6× 25 fly breathe every other stroke, chest pressed.'
            : 'Swim: 8× 25 with a quiet head — eyes down, hips high.';
      case 'turns':
        return 'Swim: 8× turn + 3 strokes out, explode then settle.';
      case 'finish':
        return 'Swim: 6× finish 15m — no breath last 3 strokes into the wall.';
      default:
        return 'Swim: 4× 25 perfect-technique at race focus.';
    }
  }
}

class _ScoredSegment {
  const _ScoredSegment({
    required this.id,
    required this.label,
    required this.signal,
    required this.whatHappened,
    required this.nextRaceCue,
    required this.swimDrills,
    required this.drylandDrills,
    required this.mentionedByAnalysis,
    required this.weight,
  });

  final String id;
  final String label;
  final OpportunitySignal signal;
  final String whatHappened;
  final String nextRaceCue;
  final List<String> swimDrills;
  final List<String> drylandDrills;
  final bool mentionedByAnalysis;
  final int weight;
}

class _Corpus {
  _Corpus({
    required this.strengths,
    required this.improvements,
    required this.raceLines,
  });

  final List<String> strengths;
  final List<PriorityImprovement> improvements;
  final List<String> raceLines;

  factory _Corpus.fromReport(AnalysisReport report) {
    return _Corpus(
      strengths: report.strengths,
      improvements: report.priorityImprovements,
      raceLines: report.raceRecommendations,
    );
  }

  PriorityImprovement? bestImprovement(List<String> keys) {
    PriorityImprovement? best;
    var bestScore = 0;
    for (final item in improvements) {
      final score = _scoreText(item.title, keys);
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    return bestScore > 0 ? best : null;
  }

  String? bestRaceLine(List<String> keys) {
    String? best;
    var bestScore = 0;
    for (final line in raceLines) {
      final score = _scoreText(line, keys);
      if (score > bestScore) {
        bestScore = score;
        best = line;
      }
    }
    return bestScore > 0 ? best : null;
  }

  String? bestStrength(List<String> keys) {
    String? best;
    var bestScore = 0;
    for (final line in strengths) {
      final score = _scoreText(line, keys);
      if (score > bestScore) {
        bestScore = score;
        best = line;
      }
    }
    return bestScore > 0 ? best : null;
  }

  static int _scoreText(String text, List<String> keys) {
    final lower = text.toLowerCase();
    var score = 0;
    for (final key in keys) {
      if (lower.contains(key)) score += 1;
    }
    return score;
  }
}
