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

  /// Rope height reflects overall SwimIQ score; today's points can push higher.
  double get climbFraction {
    final fromScore = (overallSwimIqScore / 1000).clamp(0.0, 1.0);
    final fromToday = (todayPoints / 100).clamp(0.0, 1.0);
    return fromScore > fromToday ? fromScore : fromToday;
  }

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
