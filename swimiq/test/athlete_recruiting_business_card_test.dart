import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/athlete_recruiting_business_card.dart';

void main() {
  testWidgets('AthleteRecruitingBusinessCard shows recruiting fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AthleteRecruitingBusinessCard(
            displayName: 'Aspyn Briezy',
            swimIqScore: 550,
            highestCut: 'BB',
            team: 'Central Ohio Aquatics',
            gpa: '3.85',
            website: 'https://swimiq.app/aspyn',
            topEvents: const [
              '50 Butterfly 28.45 (SCY)',
              '100 Butterfly 1:02.3 (SCY)',
            ],
            graduationYear: 2032,
          ),
        ),
      ),
    );

    expect(find.text('Aspyn Briezy'), findsOneWidget);
    expect(find.text('Central Ohio Aquatics'), findsWidgets);
    expect(find.text('550'), findsOneWidget);
    expect(find.text('BB'), findsOneWidget);
    expect(find.text('3.85'), findsOneWidget);
    expect(find.text('https://swimiq.app/aspyn'), findsOneWidget);
    expect(find.textContaining('50 Butterfly'), findsOneWidget);
  });
}
