import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import 'swim_time.dart';

/// Business logic for personal bests and SwimIQ scoring.
class SwimAnalytics {
  SwimAnalytics._();

  static List<RaceLog> personalBests(List<RaceLog> logs) {
    final valid = logs.where((log) => log.timeSeconds > 0).toList();
    if (valid.isEmpty) return [];

    final bestByEvent = <String, RaceLog>{};
    for (final log in valid) {
      final key = '${log.stroke}|${log.distance}|${log.course}';
      final existing = bestByEvent[key];
      if (existing == null || log.timeSeconds < existing.timeSeconds) {
        bestByEvent[key] = log;
      }
    }

    final results = bestByEvent.values.toList()
      ..sort((a, b) {
        final strokeCompare = a.stroke.compareTo(b.stroke);
        if (strokeCompare != 0) return strokeCompare;
        return a.distance.compareTo(b.distance);
      });
    return results;
  }

  static bool isNewPersonalBest({
    required List<RaceLog> previousLogs,
    required String stroke,
    required int distance,
    required String course,
    required double timeSeconds,
  }) {
    final matching = previousLogs.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == course &&
          log.timeSeconds > 0,
    );

    if (matching.isEmpty) return true;

    final previousBest = matching
        .map((log) => log.timeSeconds)
        .reduce((a, b) => a < b ? a : b);
    return timeSeconds < previousBest;
  }

  static int calculateSwimIqScore({
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
  }) {
    if (raceLogs.isEmpty) return 0;

    final totalSessions = raceLogs.length;
    final totalGoals = goals.length;
    final totalPbs = personalBests(raceLogs).length;

    var score = 500;
    score += totalSessions * 5;
    score += totalGoals * 20;
    score += totalPbs * 25;

    return score > 1000 ? 1000 : score;
  }

  static String bestTime(List<RaceLog> logs) {
    final times = logs.map((log) => log.timeSeconds).where((t) => t > 0);
    if (times.isEmpty) return '—';
    return SwimTime.fromSeconds(times.reduce((a, b) => a < b ? a : b));
  }

  static String averageTime(List<RaceLog> logs) {
    final times = logs.map((log) => log.timeSeconds).where((t) => t > 0);
    if (times.isEmpty) return '—';
    final sum = times.fold<double>(0, (a, b) => a + b);
    return SwimTime.fromSeconds(sum / times.length);
  }

  /// Best time for a goal event matching stroke, distance, and course.
  static double? bestTimeForGoal({
    required SwimGoal goal,
    required List<RaceLog> raceLogs,
  }) {
    final parts = goal.event.split(' ');
    if (parts.length < 2) return null;

    final distance = int.tryParse(parts.first);
    final stroke = parts.sublist(1).join(' ');
    if (distance == null) return null;

    final matching = raceLogs.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == goal.course &&
          log.timeSeconds > 0,
    );

    if (matching.isEmpty) return null;
    return matching.map((log) => log.timeSeconds).reduce((a, b) => a < b ? a : b);
  }

  /// Seconds remaining to reach goal; negative means goal achieved.
  static double? secondsToGoal({
    required SwimGoal goal,
    required List<RaceLog> raceLogs,
  }) {
    final best = bestTimeForGoal(goal: goal, raceLogs: raceLogs);
    if (best == null) return null;
    return best - goal.goalTime;
  }
}
