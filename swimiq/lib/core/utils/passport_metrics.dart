import '../../core/utils/swim_analytics.dart';
import '../../core/services/usa_standards_service.dart';
import '../../data/models/meet_result.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_video.dart';
import '../../data/models/usa_time_standard.dart';
import '../../data/models/swimmer_profile.dart';

class PassportMetrics {
  PassportMetrics._();

  static int swimIqScore({
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
  }) =>
      SwimAnalytics.calculateSwimIqScore(raceLogs: raceLogs, goals: goals);

  static String highestCut({
    required List<RaceLog> raceLogs,
    required List<UsaTimeStandard> standards,
    SwimmerProfile? profile,
  }) {
    if (standards.isEmpty || raceLogs.isEmpty) return 'Import standards';

    final pbs = SwimAnalytics.personalBests(raceLogs);
    String? bestLevel;
    final ageGroup = _ageGroup(profile);

    for (final pb in pbs) {
      final level = UsaStandardsService.highestCutForTime(
        standards: standards,
        stroke: pb.stroke,
        distance: pb.distance,
        course: pb.course,
        swimmerTime: pb.timeSeconds,
        ageGroup: ageGroup,
      );
      if (level != null) {
        if (bestLevel == null || _levelRank(level) < _levelRank(bestLevel)) {
          bestLevel = level;
        }
      }
    }

    return bestLevel ?? 'No cut yet';
  }

  static String nextMeet(List<MeetResult> meetResults) {
    if (meetResults.isEmpty) return 'Add meet results';
    final sorted = [...meetResults]
      ..sort((a, b) => b.meetDate.compareTo(a.meetDate));
    return sorted.first.meetName;
  }

  static String readiness({
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    required List<SwimVideo> videos,
  }) {
    final score = swimIqScore(raceLogs: raceLogs, goals: goals);
    final hasRecent = raceLogs.isNotEmpty;
    final hasGoals = goals.isNotEmpty;
    final hasVideo = videos.isNotEmpty;

    if (score >= 800 && hasRecent && hasGoals) return 'Race Ready';
    if (score >= 600) return 'Building';
    if (hasVideo || hasRecent) return 'Developing';
    return 'Getting Started';
  }

  static String imxScore(List<RaceLog> raceLogs) {
    final strokes = raceLogs.map((log) => log.stroke).toSet();
    if (strokes.length >= 4) return 'IMX Tracked';
    return '${strokes.length}/4 strokes';
  }

  static String _ageGroup(SwimmerProfile? profile) {
    final age = profile?.age;
    if (age == null) return '11-12';
    if (age <= 10) return '10 & Under';
    if (age <= 12) return '11-12';
    if (age <= 14) return '13-14';
    return '15-16';
  }

  static int _levelRank(String level) {
    const order = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];
    return order.indexOf(level);
  }
}
