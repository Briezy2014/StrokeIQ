import '../../data/models/meet_result.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/video_models.dart';

/// Today's climb points (0–100) drive rope height on the dashboard.
class SwimIqDailyProgress {
  const SwimIqDailyProgress({
    required this.todayPoints,
    required this.sessionsToday,
    required this.meetsToday,
    required this.videosToday,
    required this.overallSwimIqScore,
  });

  final int todayPoints;
  final int sessionsToday;
  final int meetsToday;
  final int videosToday;
  final int overallSwimIqScore;

  double get climbFraction => (todayPoints / 100).clamp(0.0, 1.0);

  /// SwimIQ score maps directly to rope height (550 of 1000 = 55% up the rope).
  static const int ropeScoreMax = 1000;

  double get scoreRopePercent =>
      (overallSwimIqScore / ropeScoreMax).clamp(0.0, 1.0);

  /// Today's logged work adds up to 10% extra climb on top of score height.
  double get todayBoostFraction => climbFraction * 0.10;

  /// Rope position: SwimIQ score height plus a small boost from today's points.
  double get ropeClimbFraction {
    if (overallSwimIqScore <= 0 && todayPoints <= 0) {
      return 0.08;
    }
    if (overallSwimIqScore <= 0) {
      return (climbFraction * 0.45 + 0.08).clamp(0.08, 1.0);
    }
    return (scoreRopePercent + todayBoostFraction).clamp(0.08, 1.0);
  }

  /// Whole-number percent shown on the rope (matches score when no boost).
  int get ropeClimbPercent => (ropeClimbFraction * 100).round();

  static SwimIqDailyProgress calculate({
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
    required List<SwimVideo> videos,
    required List<SwimGoal> goals,
    required int overallSwimIqScore,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

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

    var points = 0;
    points += sessionsToday * 20;
    points += meetsToday * 30;
    points += videosToday * 25;
    if (sessionsToday >= 2) points += 10;
    if (goals.isNotEmpty && sessionsToday > 0) points += 10;

    return SwimIqDailyProgress(
      todayPoints: points > 100 ? 100 : points,
      sessionsToday: sessionsToday,
      meetsToday: meetsToday,
      videosToday: videosToday,
      overallSwimIqScore: overallSwimIqScore,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
