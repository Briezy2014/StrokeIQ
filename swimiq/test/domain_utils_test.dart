import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/domain/utils/personal_best_utils.dart';
import 'package:swimiq/domain/utils/swim_time_utils.dart';
import 'package:swimiq/domain/utils/swimiq_score.dart';

void main() {
  group('SwimTimeUtils', () {
    test('parses seconds-only format', () {
      expect(SwimTimeUtils.swimTimeToSeconds('35.43'), 35.43);
    });

    test('parses minute format', () {
      expect(SwimTimeUtils.swimTimeToSeconds('1:24.32'), 84.32);
    });

    test('formats sub-minute times', () {
      expect(SwimTimeUtils.secondsToSwimTime(35.43), '35.43');
    });

    test('formats minute times', () {
      expect(SwimTimeUtils.secondsToSwimTime(84.32), '1:24.32');
    });
  });

  group('PersonalBestUtils', () {
    final logs = [
      RaceLogEntry(
        stroke: 'Freestyle',
        distance: 100,
        course: 'SCY',
        timeSeconds: 55.0,
        date: DateTime(2026, 1, 1),
      ),
      RaceLogEntry(
        stroke: 'Freestyle',
        distance: 100,
        course: 'SCY',
        timeSeconds: 52.5,
        date: DateTime(2026, 2, 1),
      ),
    ];

    test('detects new personal best', () {
      expect(
        PersonalBestUtils.isNewPersonalBest(
          previousLogs: logs,
          stroke: 'Freestyle',
          distance: 100,
          course: 'SCY',
          timeSeconds: 51.0,
        ),
        isTrue,
      );
    });

    test('returns best by event', () {
      final bests = PersonalBestUtils.bestByEvent(logs);
      expect(bests.length, 1);
      expect(bests.first.timeSeconds, 52.5);
    });
  });

  group('SwimIQScore', () {
    test('returns zero without logs', () {
      expect(SwimIQScore.calculate(raceLogs: [], goalCount: 0), 0);
    });

    test('calculates score with sessions and goals', () {
      final logs = [
        RaceLogEntry(
          stroke: 'Freestyle',
          distance: 50,
          course: 'SCY',
          timeSeconds: 25.0,
          date: DateTime(2026, 1, 1),
        ),
      ];

      expect(SwimIQScore.calculate(raceLogs: logs, goalCount: 1), 550);
    });
  });
}
