import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/widgets/passport_share_panel.dart';
import 'package:swimiq/widgets/recruiting_card_export_bar.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  testWidgets('PassportSharePanel shows one share section with two options', (
    tester,
  ) async {
    final snapshot = PassportMetrics.build(
      swimmerName: 'Aspyn Briez',
      profile: null,
      raceLogs: const [
        RaceLog(
          swimmer: 'Aspyn Briez',
          event: '100 Butterfly',
          distance: 100,
          stroke: 'Butterfly',
          course: 'SCY',
          timeSeconds: 61.9,
          date: DateTime(2026, 3, 15),
        ),
      ],
      goals: const [
        SwimGoal(
          swimmerName: 'Aspyn Briez',
          event: '100 Butterfly',
          goalTime: 59.99,
          course: 'SCY',
          targetDate: DateTime(2026, 11, 1),
        ),
      ],
      meetResults: const [],
      videos: const [],
      videoAnalyses: const [],
      motivationalStandards: testMotivationalCatalog,
      schedules: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PassportSharePanel(
              cardSnapshot: RecruitingCardSnapshot(
                displayName: 'Aspyn Briez',
                swimIqScore: snapshot.swimIqScore,
                highestCut: snapshot.highestCut,
                team: 'COA',
                topEvents: const ['100 Butterfly  1:01.90'],
                graduationYear: 2029,
                fileSafeName: 'Aspyn_Briez',
                gpa: '3.85',
                coach: 'Gunner Lehr',
              ),
              passportSnapshot: snapshot,
              profile: null,
              displayName: 'Aspyn Briez',
              fileSafeName: 'Aspyn_Briez',
              topEvents: const ['100 Butterfly  1:01.90'],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Share & print'), findsOneWidget);
    expect(find.text('Wallet card'), findsOneWidget);
    expect(find.text('Full passport packet'), findsOneWidget);
    expect(find.text('Aspyn Briez'), findsWidgets);
    // No duplicate orphan "Full Athlete Passport" header box.
    expect(find.text('Full Athlete Passport'), findsNothing);
    expect(find.text('Export PDF'), findsNWidgets(2));
    expect(find.text('Print'), findsNWidgets(2));
  });
}
