import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/next_cut_progress.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  final profile = SwimmerProfile(
    swimmerName: 'Aspyn',
    birthday: DateTime(2014, 3, 15),
    athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
  );

  test('next cut from BB is A with gap and progress', () {
    final progress = NextCutAnalytics.forSwim(
      catalog: testMotivationalCatalog,
      profile: profile,
      stroke: 'Freestyle',
      distance: 50,
      course: 'SCY',
      timeSeconds: 30.0,
    );

    expect(progress, isNotNull);
    expect(progress!.currentCutLabel, 'BB');
    expect(progress.nextCut, 'A');
    expect(progress.nextCutTimeSeconds, 29.29);
    expect(progress.gapSeconds, closeTo(0.71, 0.01));
    expect(progress.gapLabel, contains('0.71s'));
    expect(progress.gapLabel, contains('A'));
    expect(progress.progressPercent, greaterThan(0));
    expect(progress.progressPercent, lessThan(100));
  });

  test('below B targets B cut', () {
    final progress = NextCutAnalytics.forSwim(
      catalog: testMotivationalCatalog,
      profile: profile,
      stroke: 'Freestyle',
      distance: 50,
      course: 'SCY',
      timeSeconds: 35.0,
    );

    expect(progress!.currentCutLabel, 'Below B');
    expect(progress.nextCut, 'B');
    expect(progress.nextCutTimeSeconds, 33.99);
    expect(progress.gapSeconds, closeTo(1.01, 0.01));
  });

  test('AAAA has no next cut', () {
    final progress = NextCutAnalytics.forSwim(
      catalog: testMotivationalCatalog,
      profile: profile,
      stroke: 'Freestyle',
      distance: 50,
      course: 'SCY',
      timeSeconds: 25.0,
    );

    expect(progress!.currentCutLabel, 'AAAA');
    expect(progress.atTopCut, isTrue);
    expect(progress.hasNextCut, isFalse);
  });
}
