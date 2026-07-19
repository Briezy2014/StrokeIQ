import '../../data/models/meet_result.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../data/models/video_models.dart';
import '../utils/swim_analytics.dart';

/// Today's climb points (0–100) drive rope height on the dashboard.
class SwimIqDailyProgress {
  const SwimIqDailyProgress({
    required this.todayPoints,
    required this.sessionsToday,
    required this.meetsToday,
    required this.videosToday,
    required this.overallSwimIqScore,
    this.daysInactive = 0,
  });

  final int todayPoints;
  final int sessionsToday;
  final int meetsToday;
  final int videosToday;
  final int overallSwimIqScore;

  /// Whole days since last practice/meet/video/analysis (0 = active today).
  final int daysInactive;

  double get climbFraction => (todayPoints / 100).clamp(0.0, 1.0);

  /// SwimIQ score maps directly to rope height (550 of 1000 = 55% up the rope).
  static const int ropeScoreMax = 1000;

  double get scoreRopePercent =>
      (overallSwimIqScore / ropeScoreMax).clamp(0.0, 1.0);

  /// Today's logged work adds up to 15% extra climb on top of score height.
  double get todayBoostFraction => climbFraction * 0.15;

  /// Rope position follows SwimIQ score. Score 0 = star in the water.
  /// Today's log adds a small boost only when overall score is above zero.
  double get ropeClimbFraction {
    if (overallSwimIqScore <= 0) {
      return 0.0;
    }
    return (scoreRopePercent + todayBoostFraction).clamp(0.0, 1.0);
  }

  /// Percent on the rope — matches score when there is no daily boost.
  int get ropeClimbPercent {
    if (overallSwimIqScore <= 0) {
      return 0;
    }
    return (ropeClimbFraction * 100).round();
  }

  /// Hero chip: score-only rope height (ignores today's boost).
  int get scoreRopeClimbPercent => (scoreRopePercent * 100).round();

  static SwimIqDailyProgress calculate({
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
    required List<SwimVideo> videos,
    required List<SwimGoal> goals,
    required int overallSwimIqScore,
    List<SwimVideoAnalysis> analyses = const [],
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = _dateOnly(clock);

    final sessionsToday = raceLogs
        .where((log) => _dateOnly(log.date) == today)
        .length;
    final meetsToday = meetResults
        .where((meet) => _dateOnly(meet.meetDate) == today)
        .length;
    final videosToday = videos
        .where((video) {
          final created = video.createdAt;
          return created != null && _dateOnly(created) == today;
        })
        .length;
    final analysesToday = analyses
        .where((analysis) {
          final created = analysis.createdAt;
          return created != null && _dateOnly(created) == today;
        })
        .length;

    var points = 0;
    points += sessionsToday * 20;
    points += meetsToday * 30;
    points += videosToday * 25;
    points += analysesToday * 25;
    if (sessionsToday >= 2) points += 10;
    if (goals.isNotEmpty && sessionsToday > 0) points += 10;

    final lastActive = SwimAnalytics.lastActivityDate(
      raceLogs: raceLogs,
      meetResults: meetResults,
      videos: videos,
      analyses: analyses,
    );
    final daysInactive = lastActive == null
        ? 0
        : today.difference(_dateOnly(lastActive)).inDays.clamp(0, 9999);

    return SwimIqDailyProgress(
      todayPoints: points > 100 ? 100 : points,
      sessionsToday: sessionsToday,
      meetsToday: meetsToday,
      videosToday: videosToday + analysesToday,
      overallSwimIqScore: overallSwimIqScore,
      daysInactive: daysInactive,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
