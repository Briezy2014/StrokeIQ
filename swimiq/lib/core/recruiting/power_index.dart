import '../../data/models/meet_result.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/college_recruiting_benchmark_catalog.dart';
import '../services/usa_motivational_standards_catalog.dart';
import '../utils/swimiq_age_group.dart';
import '../utils/swimiq_gender.dart';
import '../utils/swimiq_standards_profile.dart';
import '../utils/swim_stroke_utils.dart';
import 'meet_history_analytics.dart';

/// One weighted factor in the Power Index formula (pie + legend).
class PowerIndexFactor {
  const PowerIndexFactor({
    required this.id,
    required this.label,
    required this.weightPercent,
    required this.componentScore,
    required this.weightedPoints,
    required this.explanation,
  });

  final String id;
  final String label;
  /// Formula weight as a percent (e.g. 62 for USA cuts).
  final int weightPercent;
  /// Raw 0–100 score for this factor before weighting.
  final int componentScore;
  /// Points this factor adds toward the final index (`component * weight`).
  final double weightedPoints;
  /// Plain-language meaning of this slice for parents/athletes.
  final String explanation;

  static const explanations = <String, String>{
    'cuts':
        'How fast her official best times are compared with USA Swimming '
        'motivational cuts (B → BB → A → AA → AAA → AAAA). Faster times vs '
        'those age-group standards raise this slice the most.',
    'depth':
        'How broad her racing portfolio is — more competitive events and '
        'strokes (not just one specialty) raise this score.',
    'progression':
        'Whether meet history shows real improvement over time (dropping '
        'times across seasons/meets). Steady drops raise this slice; a thin '
        'meet log stays closer to average.',
    'college':
        'How her current times line up with college recruiting time '
        'benchmarks (likely / target / reach style ranges). This is not a '
        'scholarship offer or admission decision — it only estimates how '
        'recruitable her times look today.',
    'technique':
        'Signals from SwimIQ video analysis (body mechanics / overall '
        'technique score). If there is little or no analyzed video yet, '
        'this stays near a neutral baseline.',
  };

  static String explanationFor(String id) =>
      explanations[id] ?? 'Part of the Power Index formula.';
}

/// Competitive Power Index (0–100) from official times, USA cuts, progression,
/// event depth, and optional video technique signals.
class PowerIndexSnapshot {
  const PowerIndexSnapshot({
    required this.score,
    required this.label,
    required this.summary,
    required this.hasEnoughData,
    this.strongestEvent,
    this.eventScores = const [],
    this.factors = const [],
    this.missingDataHint,
  });

  final int score;
  final String label;
  final String summary;
  final bool hasEnoughData;
  final String? strongestEvent;
  final List<PowerIndexEventScore> eventScores;
  /// Weighted formula slices used for the passport explanation chart.
  final List<PowerIndexFactor> factors;
  final String? missingDataHint;

  String get displayLine {
    if (!hasEnoughData) {
      return missingDataHint ??
          'Add official PBs and birthday/gender to calculate Power Index.';
    }
    final event = strongestEvent;
    if (event == null || event.isEmpty) {
      return '$score / 100 · $label';
    }
    return '$score / 100 · $label · strongest: $event';
  }

  String get resumeValue {
    if (!hasEnoughData) {
      return missingDataHint ??
          'Add official PBs and birthday/gender to calculate';
    }
    final event = strongestEvent;
    if (event == null || event.isEmpty) return '$score / 100 ($label)';
    return '$score / 100 ($label) · $event';
  }
}

class PowerIndexEventScore {
  const PowerIndexEventScore({
    required this.eventLabel,
    required this.score,
    required this.cutLabel,
  });

  final String eventLabel;
  final int score;
  final String cutLabel;
}

abstract final class PowerIndex {
  static const _cutFloor = <String, int>{
    'B': 42,
    'BB': 52,
    'A': 62,
    'AA': 74,
    'AAA': 86,
    'AAAA': 96,
  };

  /// Fixed formula weights (percentages must sum to 100).
  static const weightCuts = 62;
  static const weightDepth = 12;
  static const weightProgression = 12;
  static const weightCollege = 8;
  static const weightTechnique = 6;

  static PowerIndexSnapshot calculate({
    required List<PersonalBestEntry> personalBests,
    required SwimmerProfile? profile,
    required UsaMotivationalStandardsCatalog catalog,
    List<MeetResult> meetResults = const [],
    List<SwimVideoAnalysis> analyses = const [],
    CollegeRecruitingBenchmarkCatalog? benchmarkCatalog,
  }) {
    if (personalBests.isEmpty) {
      return const PowerIndexSnapshot(
        score: 0,
        label: 'Not calculated',
        summary:
            'Power Index uses your official best times against USA Swimming '
            'motivational standards.',
        hasEnoughData: false,
        missingDataHint: 'Add official personal bests to calculate Power Index',
      );
    }

    if (!SwimIqStandardsProfile.isReady(profile)) {
      return const PowerIndexSnapshot(
        score: 0,
        label: 'Not calculated',
        summary:
            'Birthday and gender are required so cuts match the correct '
            'age group and standards table.',
        hasEnoughData: false,
        missingDataHint:
            'Add birthday and gender in Athlete Passport to calculate Power Index',
      );
    }

    final ageGroup = SwimIqAgeGroup.fromProfileOrNull(profile)!;
    final gender = SwimIqGender.standardsGenderOrNull(profile)!;
    final eventScores = <PowerIndexEventScore>[];

    for (final pb in personalBests) {
      final scored = _scorePersonalBest(
        pb: pb,
        catalog: catalog,
        ageGroup: ageGroup,
        gender: gender,
      );
      if (scored != null) eventScores.add(scored);
    }

    if (eventScores.isEmpty) {
      return const PowerIndexSnapshot(
        score: 0,
        label: 'Not calculated',
        summary:
            'No matching USA Swimming standards were found for your current '
            'events. Check stroke, distance, and course on your PBs.',
        hasEnoughData: false,
        missingDataHint:
            'Update PB stroke/distance/course so USA standards can match',
      );
    }

    eventScores.sort((a, b) => b.score.compareTo(a.score));
    final top = eventScores.take(3).toList();
    final speedScore =
        top.map((e) => e.score).reduce((a, b) => a + b) / top.length;

    final depthBonus = _depthBonus(eventScores);
    final progressionBonus = _progressionBonus(meetResults, personalBests);
    final collegeBonus = _collegeBonus(
      personalBests: personalBests,
      profile: profile,
      catalog: benchmarkCatalog,
    );
    final techniqueBonus = _techniqueBonus(analyses);

    final factors = [
      PowerIndexFactor(
        id: 'cuts',
        label: 'USA cuts / speed',
        weightPercent: weightCuts,
        componentScore: speedScore.round(),
        weightedPoints: speedScore * (weightCuts / 100),
        explanation: PowerIndexFactor.explanationFor('cuts'),
      ),
      PowerIndexFactor(
        id: 'depth',
        label: 'Event depth',
        weightPercent: weightDepth,
        componentScore: depthBonus.round(),
        weightedPoints: depthBonus * (weightDepth / 100),
        explanation: PowerIndexFactor.explanationFor('depth'),
      ),
      PowerIndexFactor(
        id: 'progression',
        label: 'Meet progression',
        weightPercent: weightProgression,
        componentScore: progressionBonus.round(),
        weightedPoints: progressionBonus * (weightProgression / 100),
        explanation: PowerIndexFactor.explanationFor('progression'),
      ),
      PowerIndexFactor(
        id: 'college',
        label: 'College fit',
        weightPercent: weightCollege,
        componentScore: collegeBonus.round(),
        weightedPoints: collegeBonus * (weightCollege / 100),
        explanation: PowerIndexFactor.explanationFor('college'),
      ),
      PowerIndexFactor(
        id: 'technique',
        label: 'Video technique',
        weightPercent: weightTechnique,
        componentScore: techniqueBonus.round(),
        weightedPoints: techniqueBonus * (weightTechnique / 100),
        explanation: PowerIndexFactor.explanationFor('technique'),
      ),
    ];

    final raw =
        factors.fold<double>(0, (sum, factor) => sum + factor.weightedPoints);
    final score = raw.round().clamp(1, 100);
    final strongest = top.first;
    final label = _labelFor(score);

    return PowerIndexSnapshot(
      score: score,
      label: label,
      strongestEvent: strongest.eventLabel,
      eventScores: eventScores,
      factors: factors,
      hasEnoughData: true,
      summary:
          'Power Index $score ($label). Strongest event: ${strongest.eventLabel} '
          '(${strongest.cutLabel}). Built from USA cuts, event depth, '
          'meet progression${techniqueBonus > 40 ? ', and video technique' : ''}.',
    );
  }

  static PowerIndexEventScore? _scorePersonalBest({
    required PersonalBestEntry pb,
    required UsaMotivationalStandardsCatalog catalog,
    required String ageGroup,
    required String gender,
  }) {
    final event = catalog.eventFor(
      ageGroup: ageGroup,
      gender: gender,
      stroke: SwimStrokeUtils.canonical(pb.stroke),
      distance: pb.distance,
      course: pb.course,
    );
    if (event == null) return null;

    final cutLabel = catalog.highestCutForTime(
          stroke: pb.stroke,
          distance: pb.distance,
          course: pb.course,
          swimmerTime: pb.timeSeconds,
          ageGroup: ageGroup,
          gender: gender,
        ) ??
        'Below B';

    final score = _interpolatedCutScore(
      timeSeconds: pb.timeSeconds,
      cuts: event.cuts,
      cutLabel: cutLabel,
    );

    return PowerIndexEventScore(
      eventLabel: '${pb.displayTitle} ${pb.course}',
      score: score,
      cutLabel: cutLabel,
    );
  }

  static int _interpolatedCutScore({
    required double timeSeconds,
    required Map<String, double> cuts,
    required String cutLabel,
  }) {
    final levels = UsaMotivationalStandardsCatalog.standardLevels;
    if (cutLabel == 'Below B') {
      final b = cuts['B'];
      if (b == null || b <= 0) return 28;
      final ratio = (b / timeSeconds).clamp(0.55, 0.99);
      return (28 + (ratio - 0.55) / 0.44 * 13).round().clamp(20, 41);
    }

    final index = levels.indexOf(cutLabel);
    if (index < 0) return 40;
    final floor = _cutFloor[cutLabel] ?? 40;
    final currentCut = cuts[cutLabel];
    if (currentCut == null) return floor;

    if (index >= levels.length - 1) {
      // At/above AAAA — reward how far under the cut.
      final under = ((currentCut - timeSeconds) / currentCut).clamp(0.0, 0.12);
      return (floor + under * 33).round().clamp(floor, 100);
    }

    final nextLevel = levels[index + 1];
    final nextCut = cuts[nextLevel];
    final nextFloor = _cutFloor[nextLevel] ?? (floor + 10);
    if (nextCut == null || nextCut >= currentCut) return floor;

    final span = currentCut - nextCut;
    if (span <= 0) return floor;
    final progress = ((currentCut - timeSeconds) / span).clamp(0.0, 1.0);
    return (floor + progress * (nextFloor - floor)).round().clamp(floor, nextFloor);
  }

  static double _depthBonus(List<PowerIndexEventScore> scores) {
    if (scores.isEmpty) return 35;
    final uniqueStrokes = <String>{};
    for (final score in scores) {
      uniqueStrokes.add(score.eventLabel.split(' ').first.toLowerCase());
    }
    final count = scores.length;
    final strokeBonus = uniqueStrokes.length.clamp(1, 4) * 8.0;
    final eventBonus = count.clamp(1, 6) * 6.0;
    return (35 + strokeBonus + eventBonus).clamp(35, 95);
  }

  static double _progressionBonus(
    List<MeetResult> meetResults,
    List<PersonalBestEntry> personalBests,
  ) {
    final summary = MeetHistoryAnalytics.build(
      meetResults: meetResults,
      personalBests: personalBests,
    );
    if (summary.progressionLines.isEmpty && summary.realMeetCount == 0) {
      return 45;
    }

    var bonus = 50.0;
    bonus += summary.realMeetCount.clamp(0, 8) * 3.5;
    bonus += summary.progressionLines.length.clamp(0, 4) * 5.0;
    return bonus.clamp(40, 95);
  }

  static double _collegeBonus({
    required List<PersonalBestEntry> personalBests,
    required SwimmerProfile? profile,
    CollegeRecruitingBenchmarkCatalog? catalog,
  }) {
    if (catalog == null || catalog.programs.isEmpty) return 50;
    final matches = catalog.matchSchools(
      personalBests: personalBests,
      profile: profile,
      maxPerTier: 6,
    );
    if (matches.isEmpty) return 48;

    var points = 45.0;
    for (final match in matches) {
      switch (match.tier) {
        case CollegeMatchTier.likely:
          points += 8;
        case CollegeMatchTier.target:
          points += 5;
        case CollegeMatchTier.reach:
          points += 2;
      }
    }
    return points.clamp(40, 96);
  }

  static double _techniqueBonus(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return 40;
    final scored = analyses
        .map((a) => a.overallScore)
        .where((score) => score > 0)
        .toList();
    if (scored.isEmpty) return 45;
    scored.sort();
    final best = scored.last;
    return best.clamp(35, 95).toDouble();
  }

  static String _labelFor(int score) {
    if (score >= 90) return 'National caliber';
    if (score >= 80) return 'Elite prospect';
    if (score >= 70) return 'Highly competitive';
    if (score >= 60) return 'Competitive';
    if (score >= 48) return 'Developing';
    return 'Building base';
  }
}
