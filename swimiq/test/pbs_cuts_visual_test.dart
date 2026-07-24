import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/data/models/personal_best_entry.dart';
import 'package:swimiq/widgets/dashboard_cuts_pie_chart.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  testWidgets('PBs cuts card shows pie title and cut bars', (tester) async {
    final pbs = [
      PersonalBestEntry(
        stroke: 'Butterfly',
        distance: 50,
        course: 'SCY',
        timeSeconds: 28.5,
        date: DateTime(2026, 6, 1),
        eventLabel: '50 Butterfly',
        source: PersonalBestSource.meet,
        meetName: 'Invite',
      ),
      PersonalBestEntry(
        stroke: 'Freestyle',
        distance: 100,
        course: 'SCY',
        timeSeconds: 58.0,
        date: DateTime(2026, 6, 2),
        eventLabel: '100 Freestyle',
        source: PersonalBestSource.meet,
        meetName: 'Invite',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CutsMixCard(
              personalBests: pbs,
              raceLogs: const [],
              catalog: testMotivationalCatalog,
              profile: null,
              showProFeatures: true,
              title: 'Your USA cuts',
              subtitle:
                  'Chart of motivational cuts across your official best times.',
              showCutBars: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Your USA cuts'), findsOneWidget);
    expect(find.textContaining('events'), findsWidgets);
  });
}
