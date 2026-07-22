import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/power_index.dart';
import 'package:swimiq/core/services/usa_motivational_standards_catalog.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/personal_best_entry.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UsaMotivationalStandardsCatalog catalog;

  setUpAll(() async {
    catalog = await UsaMotivationalStandardsCatalog.loadFromAssets();
  });

  final profile = SwimmerProfile(
    swimmerName: 'Test Swimmer',
    firstName: 'Test',
    lastName: 'Swimmer',
    birthday: DateTime(2010, 6, 1),
    athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
  );

  final pbs = [
    PersonalBestEntry(
      stroke: 'Fly',
      distance: 100,
      course: 'SCY',
      timeSeconds: 58.50,
      date: DateTime(2026, 3, 1),
      eventLabel: '100 Fly',
      source: PersonalBestSource.meet,
      meetName: 'State Championships',
    ),
    PersonalBestEntry(
      stroke: 'Free',
      distance: 50,
      course: 'SCY',
      timeSeconds: 24.90,
      date: DateTime(2026, 3, 1),
      eventLabel: '50 Free',
      source: PersonalBestSource.meet,
      meetName: 'State Championships',
    ),
  ];

  test('power index requires personal bests', () {
    final snapshot = PowerIndex.calculate(
      personalBests: const [],
      profile: profile,
      catalog: catalog,
    );
    expect(snapshot.hasEnoughData, isFalse);
    expect(snapshot.resumeValue.toLowerCase(), contains('personal best'));
  });

  test('power index requires birthday and gender', () {
    final incomplete = SwimmerProfile(
      swimmerName: 'No Birthday',
      athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
    );
    final snapshot = PowerIndex.calculate(
      personalBests: pbs,
      profile: incomplete,
      catalog: catalog,
    );
    expect(snapshot.hasEnoughData, isFalse);
    expect(snapshot.resumeValue.toLowerCase(), contains('birthday'));
  });

  test('power index calculates active score from PBs and standards', () {
    final snapshot = PowerIndex.calculate(
      personalBests: pbs,
      profile: profile,
      catalog: catalog,
      meetResults: [
        MeetResult(
          swimmerName: 'Test Swimmer',
          meetName: 'State Championships',
          event: '100 Fly',
          swimTime: 58.50,
          course: 'SCY',
          meetDate: DateTime(2026, 2, 15),
        ),
        MeetResult(
          swimmerName: 'Test Swimmer',
          meetName: 'Winter Invite',
          event: '100 Fly',
          swimTime: 60.10,
          course: 'SCY',
          meetDate: DateTime(2025, 12, 1),
        ),
      ],
    );

    expect(snapshot.hasEnoughData, isTrue);
    expect(snapshot.score, inInclusiveRange(1, 100));
    expect(snapshot.label, isNotEmpty);
    expect(snapshot.strongestEvent, isNotNull);
    expect(snapshot.resumeValue, isNot(contains('coming soon')));
    expect(snapshot.displayLine.toLowerCase(), isNot(contains('coming soon')));
  });
}
