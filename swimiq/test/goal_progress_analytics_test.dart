import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/goal_progress_analytics.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';

void main() {
  test('goal progress uses fastest meet result over training log', () {
    final goal = SwimGoal(
      swimmerName: 'Aspyn',
      event: '100 Butterfly',
      goalTime: 66,
      course: 'SCY',
      targetDate: DateTime(2026, 10, 1),
    );

    final best = GoalProgressAnalytics.bestTime(
      goal: goal,
      raceLogs: [
        RaceLog(
          swimmer: 'Aspyn',
          event: '100 Butterfly',
          distance: 100,
          stroke: 'Butterfly',
          course: 'SCY',
          timeSeconds: 72,
          date: DateTime(2026, 6, 1),
        ),
      ],
      meetResults: [
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Districts',
          event: '100 Butterfly',
          swimTime: 68.5,
          course: 'SCY',
          meetDate: DateTime(2026, 7, 1),
        ),
      ],
    );

    expect(best, 68.5);

    final history = GoalProgressAnalytics.timeHistory(
      goal: goal,
      raceLogs: const [],
      meetResults: [
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Districts',
          event: '100 Butterfly',
          swimTime: 68.5,
          course: 'SCY',
          meetDate: DateTime(2026, 7, 1),
        ),
      ],
    );

    expect(history, hasLength(1));
    expect(history.first.sourceLabel, 'Meet');
  });
}
