import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/constants/app_constants.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('loads official 2024-2028 motivational standards bundle', () {
    expect(testMotivationalCatalog.versionLabel,
        '2024-2028 USA Swimming Motivational Standards');
    expect(testMotivationalCatalog.events.length, 500);
    expect(testMotivationalCatalog.flatStandards.length, 3000);
  });

  test('11-12 Girls 50 Freestyle SCY matches PDF values', () {
    final event = testMotivationalCatalog.eventFor(
      ageGroup: '11-12',
      gender: 'Girls',
      stroke: 'Freestyle',
      distance: 50,
      course: 'SCY',
    );

    expect(event, isNotNull);
    expect(event!.cuts['B'], 33.99);
    expect(event.cuts['BB'], 31.69);
    expect(event.cuts['A'], 29.29);
    expect(event.cuts['AA'], 28.09);
    expect(event.cuts['AAA'], 26.99);
    expect(event.cuts['AAAA'], 25.79);
  });

  test('highestCutForTime returns AAAA for faster-than-AAAA swim', () {
    final cut = testMotivationalCatalog.highestCutForTime(
      stroke: 'Freestyle',
      distance: 50,
      course: 'SCY',
      swimmerTime: 25.0,
      ageGroup: '11-12',
      gender: 'Girls',
    );
    expect(cut, 'AAAA');
  });

  test('search filters by course and stroke', () {
    final results = testMotivationalCatalog.search(
      course: 'LCM',
      stroke: 'Butterfly',
      query: '50',
    );
    expect(results, isNotEmpty);
    expect(results.every((event) => event.course == 'LCM'), isTrue);
  });

  test('bundle includes all official age groups genders and courses', () {
    final events = testMotivationalCatalog.events;
    expect(events.map((e) => e.ageGroup).toSet(),
        containsAll(AppConstants.ageGroups));
    expect(events.map((e) => e.gender).toSet(),
        containsAll(AppConstants.genders));
    expect(events.map((e) => e.course).toSet(),
        containsAll(AppConstants.courses));
  });
}
