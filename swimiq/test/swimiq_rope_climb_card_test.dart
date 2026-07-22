import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/gamification/swimiq_daily_progress.dart';
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

    expect(find.text('550/1000'), findsOneWidget);
    expect(find.text('550/1000 · 55%'), findsNothing);
    expect(find.text("Today's log"), findsOneWidget);
    expect(find.text('0/100'), findsOneWidget);
    expect(find.textContaining('550 out of 1000'), findsOneWidget);
    expect(find.textContaining('55%'), findsWidgets);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });
}
