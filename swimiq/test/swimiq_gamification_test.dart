import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/gamification/swimiq_badges.dart';
import 'package:swimiq/core/gamification/swimiq_daily_progress.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/data/models/race_log.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('daily progress awards points for today sessions', () {
    final today = DateTime.now();
    final progress = SwimIqDailyProgress.calculate(
      raceLogs: [
        RaceLog(
          swimmer: 'Aspyn',
          event: '50 Free',
          distance: 50,
          stroke: 'Freestyle',
          course: 'SCY',
          timeSeconds: 28,
          date: today,
        ),
      ],
      meetResults: const [],
      videos: const [],
      goals: const [],
      overallSwimIqScore: 550,
    );

    expect(progress.todayPoints, 20);
    expect(progress.climbFraction, 0.55);
  });

  test('climb height follows overall SwimIQ score when no activity today', () {
    final progress = SwimIqDailyProgress.calculate(
      raceLogs: const [],
      meetResults: const [],
      videos: const [],
      goals: const [],
      overallSwimIqScore: 550,
    );

    expect(progress.todayPoints, 0);
    expect(progress.climbFraction, 0.55);
  });

  test('badge catalog includes earned first splash', () {
    final logs = [
      RaceLog(
        swimmer: 'Aspyn',
        event: '50 Free',
        distance: 50,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: 28,
        date: DateTime.now(),
      ),
    ];
    final daily = SwimIqDailyProgress.calculate(
      raceLogs: logs,
      meetResults: const [],
      videos: const [],
      goals: const [],
      overallSwimIqScore: 550,
    );
    final snapshot = PassportMetrics.build(
      swimmerName: 'Aspyn',
      profile: null,
      raceLogs: logs,
      goals: const [],
      meetResults: const [],
      videos: const [],
      videoAnalyses: const [],
      motivationalStandards: testMotivationalCatalog,
    );

    final badges = SwimIqBadgeCatalog.evaluate(
      daily: daily,
      raceLogs: logs,
      meetResults: const [],
      goals: const [],
      personalBests: const [],
      videos: const [],
      analyses: const [],
      profile: null,
      snapshot: snapshot,
    );

    expect(badges.where((badge) => badge.id == 'first_splash').first.isEarned, isTrue);
    expect(badges.length, greaterThan(15));
  });
}
