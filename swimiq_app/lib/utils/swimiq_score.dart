import '../models/goal.dart';
import '../models/race_log.dart';
import 'personal_bests.dart';

class SwimIQScore {
  static int calculate(List<RaceLog> raceLogs, List<Goal> goals) {
    if (raceLogs.isEmpty) return 0;

    final totalSessions = raceLogs.length;
    final totalGoals = goals.length;
    final totalPbs = PersonalBests.fromRaceLogs(raceLogs).length;

    var score = 500;
    score += totalSessions * 5;
    score += totalGoals * 20;
    score += totalPbs * 25;

    return score > 1000 ? 1000 : score;
  }
}
