import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/gamification/swimiq_daily_progress.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_rope_climb_card.dart';

void main() {
  testWidgets('rope card shows score-linked climb percent', (tester) async {
    const daily = SwimIqDailyProgress(
      todayPoints: 0,
      sessionsToday: 0,
      meetsToday: 0,
      videosToday: 0,
      overallSwimIqScore: 550,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwimIqRopeClimbCard(
            daily: daily,
            badges: const [],
          ),
        ),
      ),
    );

    expect(find.text('55% · Score 550'), findsOneWidget);
    expect(find.textContaining('SwimIQ Score 550 = 55% up the rope'), findsOneWidget);
    expect(find.byType(SwimIqBrandedImage), findsOneWidget);
    expect(find.text('🏊'), findsNothing);
  });
}
