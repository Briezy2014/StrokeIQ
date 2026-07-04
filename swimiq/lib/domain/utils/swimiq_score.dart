import 'personal_best_utils.dart';

/// Version 2 SwimIQ Score — ported from the Streamlit application.
///
/// Simple and explainable:
/// - Starts at 500 once the swimmer has logs
/// - Adds points for sessions, goals, and PBs
/// - Caps at 1000
class SwimIQScore {
  SwimIQScore._();

  static int calculate({
    required List<RaceLogEntry> raceLogs,
    required int goalCount,
  }) {
    if (raceLogs.isEmpty) return 0;

    final totalSessions = raceLogs.length;
    final totalPbs = PersonalBestUtils.bestByEvent(raceLogs).length;

    var score = 500;
    score += totalSessions * 5;
    score += goalCount * 20;
    score += totalPbs * 25;

    return score > 1000 ? 1000 : score;
  }
}
