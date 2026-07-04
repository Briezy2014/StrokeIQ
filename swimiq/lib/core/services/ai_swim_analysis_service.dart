import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_video.dart';
import '../../data/models/swimmer_profile.dart';

/// Rule-based swim analysis for V1. Can be replaced by a Supabase Edge Function later.
class AiSwimAnalysisService {
  SwimVideoAnalysis analyze({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
    List<UsaTimeStandard> standards = const [],
  }) {
    final stroke = video.stroke ?? profile?.primaryStroke ?? 'Freestyle';
    final distance = video.distance ?? 100;
    final course = video.course ?? 'SCY';

    final matchingLogs = raceLogs.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == course,
    );

    final pb = matchingLogs.isEmpty
        ? null
        : matchingLogs
            .map((log) => log.timeSeconds)
            .reduce((a, b) => a < b ? a : b);

    final totalSessions = raceLogs.length;
    final totalGoals = goals.length;
    final totalPbs = SwimAnalytics.personalBests(raceLogs).length;

    var techniqueScore = 65;
    var paceScore = 60;

    if (totalSessions >= 5) techniqueScore += 10;
    if (totalSessions >= 15) techniqueScore += 10;
    if (totalPbs >= 2) paceScore += 15;
    if (totalGoals >= 1) paceScore += 5;

    if (video.notes != null && video.notes!.toLowerCase().contains('stroke')) {
      techniqueScore += 5;
    }

    techniqueScore = techniqueScore.clamp(40, 95);
    paceScore = paceScore.clamp(40, 95);
    final overallScore = ((techniqueScore + paceScore) / 2).round();

    final strengths = <String>[
      if (totalSessions > 0)
        'Consistent training history with $totalSessions logged sessions.',
      if (pb != null)
        'Current best for $distance $stroke ($course): ${SwimTime.fromSeconds(pb)}.',
      if (profile?.primaryStroke != null)
        'Primary stroke focus: ${profile!.primaryStroke}.',
    ];

    final improvements = <String>[
      'Film side and underwater angles for better stroke review.',
      'Log stroke count and splits in video notes for richer analysis.',
      if (totalGoals == 0)
        'Add a goal for $distance $stroke to track progress against target pace.',
      if (pb == null)
        'Add a training session for this event to unlock PB comparisons.',
    ];

    final standardMatch = _bestStandardMatch(
      standards: standards,
      stroke: stroke,
      distance: distance,
      course: course,
      swimmerTime: pb,
      profile: profile,
    );

    final summary = StringBuffer()
      ..write(
        'AI Swim Analysis for ${video.displayTitle}: ',
      )
      ..write(
        'Overall readiness score $overallScore/100. ',
      );
    if (standardMatch != null) {
      summary.write('Highest comparable USA cut detected: $standardMatch. ');
    }
    summary.write(
      'This V1 analysis uses training history, goals, and video metadata. '
      'Connect a future Edge Function for frame-by-frame technique scoring.',
    );

    return SwimVideoAnalysis(
      swimVideoId: video.id,
      swimmerName: video.swimmerName,
      summary: summary.toString(),
      strengths: strengths.isEmpty
          ? 'Keep uploading videos to build your analysis profile.'
          : strengths.join(' '),
      improvements: improvements.join(' '),
      techniqueScore: techniqueScore,
      paceScore: paceScore,
      overallScore: overallScore,
      analysisJson: {
        'stroke': stroke,
        'distance': distance,
        'course': course,
        'personal_best_seconds': pb,
        'standard_match': standardMatch,
        'engine': 'swimiq-v1-rules',
      },
    );
  }

  String? _bestStandardMatch({
    required List<UsaTimeStandard> standards,
    required String stroke,
    required int distance,
    required String course,
    required double? swimmerTime,
    SwimmerProfile? profile,
  }) {
    if (swimmerTime == null || standards.isEmpty) return null;

    final gender = _inferGender(profile);
    final ageGroup = _inferAgeGroup(profile);

    final matches = standards.where(
      (standard) =>
          standard.stroke == stroke &&
          standard.distance == distance &&
          standard.course == course &&
          (gender == null || standard.gender == gender) &&
          (ageGroup == null || standard.ageGroup == ageGroup) &&
          swimmerTime <= standard.timeSeconds,
    );

    if (matches.isEmpty) return null;

    const levelOrder = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];
    matches.toList().sort(
          (a, b) => levelOrder
              .indexOf(a.standardLevel)
              .compareTo(levelOrder.indexOf(b.standardLevel)),
        );
    final best = matches.first;
    return '${best.standardLevel} (${SwimTime.fromSeconds(best.timeSeconds)})';
  }

  String? _inferGender(SwimmerProfile? profile) {
    return null;
  }

  String? _inferAgeGroup(SwimmerProfile? profile) {
    final age = profile?.age;
    if (age == null) return '11-12';
    if (age <= 10) return '10 & Under';
    if (age <= 12) return '11-12';
    if (age <= 14) return '13-14';
    return '15-16';
  }
}
