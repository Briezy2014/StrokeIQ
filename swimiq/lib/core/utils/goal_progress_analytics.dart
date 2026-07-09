import '../../data/models/meet_result.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/usa_motivational_standards_catalog.dart';
import 'motivational_cut.dart';
import 'swim_event_parser.dart';

/// A logged swim point for charting goal progress over time.
class GoalTimePoint {
  const GoalTimePoint({
    required this.date,
    required this.timeSeconds,
    required this.sourceLabel,
  });

  final DateTime date;
  final double timeSeconds;
  final String sourceLabel;
}

enum GoalProgressStatus { noData, building, close, achieved }

/// Computed progress for one [SwimGoal] using training logs + meet results.
class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.goal,
    required this.bestTime,
    required this.secondsToGoal,
    required this.progressPercent,
    required this.status,
    required this.currentCut,
    required this.goalCut,
    required this.history,
  });

  final SwimGoal goal;
  final double? bestTime;
  final double? secondsToGoal;
  final double progressPercent;
  final GoalProgressStatus status;
  final String currentCut;
  final String goalCut;
  final List<GoalTimePoint> history;

  bool get isAchieved => status == GoalProgressStatus.achieved;
}

abstract final class GoalProgressAnalytics {
  GoalProgressAnalytics._();

  static GoalProgressSnapshot snapshot({
    required SwimGoal goal,
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
  }) {
    final parts = SwimEventParser.parse(goal.event);
    final history = timeHistory(
      goal: goal,
      raceLogs: raceLogs,
      meetResults: meetResults,
    );
    final best = bestTime(
      goal: goal,
      raceLogs: raceLogs,
      meetResults: meetResults,
    );
    final toGoal = best == null ? null : best - goal.goalTime;
    final progress = _progressPercent(best: best, goalTime: goal.goalTime);
    final status = _status(best: best, toGoal: toGoal);

    final currentCut = best == null || parts == null
        ? '—'
        : MotivationalCut.labelForSwim(
            catalog: catalog,
            profile: profile,
            stroke: parts.stroke,
            distance: parts.distance,
            course: goal.course,
            timeSeconds: best,
          );
    final goalCut = parts == null
        ? '—'
        : MotivationalCut.labelForSwim(
            catalog: catalog,
            profile: profile,
            stroke: parts.stroke,
            distance: parts.distance,
            course: goal.course,
            timeSeconds: goal.goalTime,
          );

    return GoalProgressSnapshot(
      goal: goal,
      bestTime: best,
      secondsToGoal: toGoal,
      progressPercent: progress,
      status: status,
      currentCut: currentCut,
      goalCut: goalCut,
      history: history,
    );
  }

  static List<GoalProgressSnapshot> allSnapshots({
    required List<SwimGoal> goals,
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
  }) {
    return goals
        .map(
          (goal) => snapshot(
            goal: goal,
            raceLogs: raceLogs,
            meetResults: meetResults,
            catalog: catalog,
            profile: profile,
          ),
        )
        .toList();
  }

  static double? bestTime({
    required SwimGoal goal,
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
  }) {
    final parts = SwimEventParser.parse(goal.event);
    if (parts == null) return null;

    final times = <double>[];

    for (final log in raceLogs) {
      if (log.stroke == parts.stroke &&
          log.distance == parts.distance &&
          log.course == goal.course &&
          log.timeSeconds > 0) {
        times.add(log.timeSeconds);
      }
    }

    for (final result in meetResults) {
      final resultParts = SwimEventParser.parse(result.event);
      if (resultParts == null) continue;
      if (resultParts.stroke == parts.stroke &&
          resultParts.distance == parts.distance &&
          result.course == goal.course &&
          result.swimTime > 0) {
        times.add(result.swimTime);
      }
    }

    if (times.isEmpty) return null;
    return times.reduce((a, b) => a < b ? a : b);
  }

  static List<GoalTimePoint> timeHistory({
    required SwimGoal goal,
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
  }) {
    final parts = SwimEventParser.parse(goal.event);
    if (parts == null) return const [];

    final points = <GoalTimePoint>[];

    for (final log in raceLogs) {
      if (log.stroke == parts.stroke &&
          log.distance == parts.distance &&
          log.course == goal.course &&
          log.timeSeconds > 0) {
        points.add(
          GoalTimePoint(
            date: log.date,
            timeSeconds: log.timeSeconds,
            sourceLabel: 'Training',
          ),
        );
      }
    }

    for (final result in meetResults) {
      final resultParts = SwimEventParser.parse(result.event);
      if (resultParts == null) continue;
      if (resultParts.stroke == parts.stroke &&
          resultParts.distance == parts.distance &&
          result.course == goal.course &&
          result.swimTime > 0) {
        points.add(
          GoalTimePoint(
            date: result.meetDate,
            timeSeconds: result.swimTime,
            sourceLabel: 'Meet',
          ),
        );
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  static double _progressPercent({
    required double? best,
    required double goalTime,
  }) {
    if (best == null || goalTime <= 0) return 0;
    if (best <= goalTime) return 100;
    final gap = best - goalTime;
    final window = goalTime * 0.3;
    return ((1 - gap / window).clamp(0.0, 1.0) * 100);
  }

  static GoalProgressStatus _status({
    required double? best,
    required double? toGoal,
  }) {
    if (best == null) return GoalProgressStatus.noData;
    if (toGoal != null && toGoal <= 0) return GoalProgressStatus.achieved;
    if (toGoal != null && toGoal <= 2) return GoalProgressStatus.close;
    return GoalProgressStatus.building;
  }
}
