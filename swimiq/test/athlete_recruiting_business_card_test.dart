import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/recruiting_top_event.dart';
import 'package:swimiq/data/models/personal_best_entry.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/widgets/athlete_recruiting_business_card.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  testWidgets('AthleteRecruitingBusinessCard shows wallet recruiting fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AthleteRecruitingBusinessCard(
              displayName: 'Aspyn Briezy',
              swimIqScore: 550,
              highestCut: 'BB',
              team: 'Central Ohio Aquatics',
              coach: 'Gunner Lehr',
              gpa: '3.85',
              website: 'https://swimiq.app/aspyn',
              email: 'aspyn@example.com',
              phone: '(614) 555-0199',
              topEvents: [
                RecruitingTopEvent(line: '50 Butterfly 28.45 (SCY)', cut: 'A'),
                RecruitingTopEvent(
                  line: '100 Butterfly 1:02.3 (SCY)',
                  cut: 'BB',
                ),
                RecruitingTopEvent(
                  line: '200 Butterfly 2:20.1 (SCY)',
                  cut: 'BB',
                ),
              ],
              graduationYear: 2032,
              usaSwimmingId: 'AB1234E5F',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Aspyn Briezy'), findsOneWidget);
    expect(find.text('SWIMIQ'), findsOneWidget);
    expect(find.text('550'), findsOneWidget);
    expect(find.textContaining('Class of 2032'), findsOneWidget);
    expect(find.textContaining('Central Ohio Aquatics'), findsOneWidget);
    expect(find.text('Gunner Lehr'), findsOneWidget);
    expect(find.text('https://swimiq.app/aspyn'), findsOneWidget);
    expect(find.text('aspyn@example.com'), findsOneWidget);
    expect(find.text('(614) 555-0199'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('BB'), findsWidgets);
    expect(find.text('HIGHEST USA CUT'), findsNothing);
    expect(find.text('Motivational standard'), findsNothing);
    expect(find.text('TOP TIMES'), findsOneWidget);
    expect(find.textContaining('GPA 3.85'), findsOneWidget);
    expect(find.textContaining('50 Butterfly'), findsOneWidget);
    expect(find.textContaining('100 Butterfly'), findsOneWidget);
    expect(find.textContaining('200 Butterfly'), findsOneWidget);
    expect(find.textContaining('STATE QUALIFIER'), findsOneWidget);
  });

  test('topEventLines returns up to three personal bests', () {
    final lines = AthleteRecruitingBusinessCard.topEventLines([
      PersonalBestEntry(
        stroke: 'Fly',
        distance: 50,
        course: 'SCY',
        timeSeconds: 28.45,
        date: DateTime(2026, 3, 1),
        eventLabel: '50 Fly',
        source: PersonalBestSource.meet,
      ),
      PersonalBestEntry(
        stroke: 'Fly',
        distance: 100,
        course: 'SCY',
        timeSeconds: 62.3,
        date: DateTime(2026, 3, 1),
        eventLabel: '100 Fly',
        source: PersonalBestSource.meet,
      ),
      PersonalBestEntry(
        stroke: 'Fly',
        distance: 200,
        course: 'SCY',
        timeSeconds: 140.1,
        date: DateTime(2026, 3, 1),
        eventLabel: '200 Fly',
        source: PersonalBestSource.meet,
      ),
      PersonalBestEntry(
        stroke: 'Free',
        distance: 50,
        course: 'SCY',
        timeSeconds: 26.0,
        date: DateTime(2026, 3, 1),
        eventLabel: '50 Free',
        source: PersonalBestSource.meet,
      ),
    ]);

    expect(lines, hasLength(3));
    expect(lines[0], contains('50'));
    expect(lines[1], contains('100'));
    expect(lines[2], contains('200'));
  });

  test('per-event cuts do not copy overall highest cut onto slower swims', () {
    final profile = SwimmerProfile(
      swimmerName: 'Aspyn',
      birthday: DateTime(2014, 6, 8),
      athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
    );
    final events = RecruitingTopEvent.fromPersonalBests(
      personalBests: [
        PersonalBestEntry(
          stroke: 'Butterfly',
          distance: 50,
          course: 'SCY',
          timeSeconds: 34.67,
          date: DateTime(2026, 3, 1),
          eventLabel: '50 Butterfly',
          source: PersonalBestSource.meet,
        ),
        PersonalBestEntry(
          stroke: 'Butterfly',
          distance: 200,
          course: 'SCY',
          timeSeconds: 187.83, // 3:07.83
          date: DateTime(2026, 3, 1),
          eventLabel: '200 Butterfly',
          source: PersonalBestSource.meet,
        ),
      ],
      catalog: testMotivationalCatalog,
      profile: profile,
    );

    expect(events, hasLength(2));
    expect(events[0].cut, isNot(equals(events[1].cut)),
        reason: '50 and 200 Fly must not share one pasted cut badge');
    // 3:07 SCY for 11-12 girls should not be an A if standards say BB.
    expect(events[1].cut, isNot(equals('A')));
    expect(events[1].cut, anyOf(equals('BB'), equals('B'), isNull));
  });

  testWidgets('AthleteRecruitingBusinessCard shows upload photo action', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AthleteRecruitingBusinessCard(
              displayName: 'Aspyn Briezy',
              swimIqScore: 550,
              highestCut: 'A',
              team: 'Central Ohio Aquatics',
              coach: null,
              gpa: '4.0',
              website: null,
              topEvents: const [
                RecruitingTopEvent(line: '50 Butterfly 34.67', cut: 'A'),
              ],
              onUploadPhoto: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add photo'), findsOneWidget);
    expect(find.text('Add coach'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // cut beside the real top time
    expect(find.text('HIGHEST USA CUT'), findsNothing);
    expect(find.textContaining('50 Butterfly 34.67'), findsOneWidget);
    expect(find.text('Add 3rd PB'), findsOneWidget);
    await tester.tap(find.text('Add photo'));
    expect(tapped, isTrue);
  });
}
