import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_analytics.dart';
import 'package:swimiq/core/utils/swim_time.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';

void main() {
  group('SwimTime', () {
    test('parses seconds format', () {
      expect(SwimTime.toSeconds('35.43'), 35.43);
    });

    test('parses minutes format', () {
      expect(SwimTime.toSeconds('1:24.32'), 84.32);
    });

    test('formats short times', () {
      expect(SwimTime.fromSeconds(35.43), '35.43');
    });

    test('formats long times', () {
      expect(SwimTime.fromSeconds(84.32), '1:24.32');
    });
  });

  group('SwimAnalytics', () {
    final logs = [
      RaceLog(
        swimmer: 'Aspyn',
        event: '100 Freestyle',
        distance: 100,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: 60,
        date: DateTime(2026, 1, 1),
      ),
      RaceLog(
        swimmer: 'Aspyn',
        event: '100 Freestyle',
        distance: 100,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: 55,
        date: DateTime(2026, 2, 1),
      ),
    ];

    test('detects personal bests', () {
      final pbs = SwimAnalytics.personalBests(logs);
      expect(pbs.length, 1);
      expect(pbs.first.timeSeconds, 55);
    });

    test('calculates SwimIQ score', () {
      final score = SwimAnalytics.calculateSwimIqScore(
        raceLogs: logs,
        goals: [
          SwimGoal(
            swimmerName: 'Aspyn',
            event: '200 Butterfly',
            goalTime: 120,
            course: 'LCM',
            targetDate: DateTime(2026, 6, 1),
          ),
        ],
      );
      expect(score, 555);
    });
  });
}
