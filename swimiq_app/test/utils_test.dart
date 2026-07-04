import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq_app/models/goal.dart';
import 'package:swimiq_app/models/race_log.dart';
import 'package:swimiq_app/utils/personal_bests.dart';
import 'package:swimiq_app/utils/swim_time.dart';
import 'package:swimiq_app/utils/swimiq_score.dart';

void main() {
  group('SwimTime', () {
    test('converts seconds format', () {
      expect(SwimTime.toSeconds('35.43'), 35.43);
    });

    test('converts minute format', () {
      expect(SwimTime.toSeconds('1:24.32'), 84.32);
    });

    test('formats short times', () {
      expect(SwimTime.fromSeconds(35.43), '35.43');
    });

    test('formats long times', () {
      expect(SwimTime.fromSeconds(84.32), '1:24.32');
    });
  });

  group('PersonalBests', () {
    test('finds best time per event', () {
      final logs = [
        RaceLog(
          swimmer: 'Aspyn',
          event: '100 Free',
          distance: 100,
          stroke: 'Freestyle',
          course: 'SCY',
          timeSeconds: 60,
          date: '2026-01-01',
        ),
        RaceLog(
          swimmer: 'Aspyn',
          event: '100 Free',
          distance: 100,
          stroke: 'Freestyle',
          course: 'SCY',
          timeSeconds: 55,
          date: '2026-02-01',
        ),
      ];

      final pbs = PersonalBests.fromRaceLogs(logs);
      expect(pbs.length, 1);
      expect(pbs.first.timeSeconds, 55);
    });
  });

  group('SwimIQScore', () {
    test('returns zero without logs', () {
      expect(SwimIQScore.calculate([], []), 0);
    });

    test('calculates score with activity', () {
      final logs = [
        RaceLog(
          swimmer: 'Aspyn',
          event: '100 Free',
          distance: 100,
          stroke: 'Freestyle',
          course: 'SCY',
          timeSeconds: 60,
          date: '2026-01-01',
        ),
      ];
      final goals = [
        Goal(
          swimmerName: 'Aspyn',
          event: '100 Free',
          goalTime: 55,
          course: 'SCY',
          targetDate: '2026-12-01',
        ),
      ];

      expect(SwimIQScore.calculate(logs, goals), 550);
    });
  });
}
