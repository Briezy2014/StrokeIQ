import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/race_log.dart';
import '../../domain/utils/personal_best_utils.dart';
import '../../domain/utils/swim_time_utils.dart';
import '../../domain/utils/swimiq_score.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/race_log_repository.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.swimIqScore,
    required this.totalSessions,
    required this.personalBests,
    required this.activeGoals,
    required this.bestTime,
    required this.averageTime,
    required this.raceLogs,
  });

  final int swimIqScore;
  final int totalSessions;
  final int personalBests;
  final int activeGoals;
  final String bestTime;
  final String averageTime;
  final List<RaceLog> raceLogs;
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final raceLogs = await ref.watch(raceLogsProvider.future);
  final goals = await ref.watch(goalsProvider.future);

  final entries = raceLogs.map((log) => log.toEntry()).toList();
  final personalBests = PersonalBestUtils.bestByEvent(entries);

  final times = raceLogs.map((log) => log.timeSeconds).where((t) => t > 0).toList();
  String bestTime = '—';
  String averageTime = '—';

  if (times.isNotEmpty) {
    bestTime = SwimTimeUtils.secondsToSwimTime(times.reduce((a, b) => a < b ? a : b));
    final average = times.reduce((a, b) => a + b) / times.length;
    averageTime = SwimTimeUtils.secondsToSwimTime(average);
  }

  return DashboardSummary(
    swimIqScore: SwimIQScore.calculate(
      raceLogs: entries,
      goalCount: goals.length,
    ),
    totalSessions: raceLogs.length,
    personalBests: personalBests.length,
    activeGoals: goals.length,
    bestTime: bestTime,
    averageTime: averageTime,
    raceLogs: raceLogs,
  );
});
