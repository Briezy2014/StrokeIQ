import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq_mobile/models/motivational_standard.dart';
import 'package:swimiq_mobile/models/standard_level.dart';
import 'package:swimiq_mobile/services/standards_analytics.dart';

MotivationalStandard _testStandard() {
  return const MotivationalStandard(
    ageGroup: '13-14',
    gender: 'F',
    course: 'SCY',
    event: '100 Freestyle',
    bTime: 80.0,
    bbTime: 75.0,
    aTime: 70.0,
    aaTime: 65.0,
    aaaTime: 60.0,
    aaaaTime: 55.0,
    version: 'test-version',
  );
}

void main() {
  group('StandardsAnalytics', () {
    final standard = _testStandard();

    test('bestStandardAchieved returns highest achieved level', () {
      expect(
        StandardsAnalytics.bestStandardAchieved(
          swimTimeSeconds: 64.0,
          standard: standard,
        ),
        StandardLevel.aa,
      );
    });

    test('nextStandard returns upcoming level', () {
      expect(
        StandardsAnalytics.nextStandard(
          swimTimeSeconds: 64.0,
          standard: standard,
        ),
        StandardLevel.aaa,
      );
    });

    test('timeToNextStandard calculates seconds to next cutoff', () {
      expect(
        StandardsAnalytics.timeToNextStandard(
          swimTimeSeconds: 64.0,
          standard: standard,
        ),
        4.0,
      );
    });

    test('percentProgress is between 0 and 100', () {
      final progress = StandardsAnalytics.percentProgress(
        swimTimeSeconds: 62.5,
        standard: standard,
      );
      expect(progress, isNotNull);
      expect(progress!, greaterThan(0));
      expect(progress, lessThanOrEqualTo(100));
    });

    test('goalTimeForLevel returns cutoff for selected level', () {
      expect(
        StandardsAnalytics.goalTimeForLevel(
          standard: standard,
          level: StandardLevel.aa,
        ),
        65.0,
      );
    });

    test('coachInsight references current and next levels', () {
      final comparison = StandardsAnalytics.compare(
        swimTimeSeconds: 64.0,
        standard: standard,
      );

      final message = StandardsAnalytics.coachInsight(
        comparison: comparison,
        event: '100 Freestyle',
      );

      expect(message.contains('AA'), isTrue);
      expect(message.contains('AAA'), isTrue);
    });
  });
}
