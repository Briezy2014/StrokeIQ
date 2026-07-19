import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/athlete_recruiting_business_card.dart';

void main() {
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
              gpa: '3.85',
              website: 'https://swimiq.app/aspyn',
              email: 'aspyn@example.com',
              phone: '(614) 555-0199',
              topEvents: [
                '50 Butterfly 28.45 (SCY)',
                '100 Butterfly 1:02.3 (SCY)',
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
    expect(find.text('https://swimiq.app/aspyn'), findsOneWidget);
    expect(find.text('aspyn@example.com'), findsOneWidget);
    expect(find.text('(614) 555-0199'), findsOneWidget);
    expect(find.text('BB'), findsOneWidget);
    expect(find.textContaining('50 Butterfly'), findsOneWidget);
    expect(find.textContaining('STATE QUALIFIER'), findsOneWidget);
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
              gpa: '4.0',
              website: null,
              topEvents: const [],
              onUploadPhoto: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add photo'), findsOneWidget);
    await tester.tap(find.text('Add photo'));
    expect(tapped, isTrue);
  });
}
