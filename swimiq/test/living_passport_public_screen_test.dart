import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/living_passport_payload.dart';
import 'package:swimiq/widgets/living_passport_public_screen.dart';

void main() {
  testWidgets('Living Passport public screen shows recruiter visuals',
      (tester) async {
    const payload = LivingPassportPayload(
      displayName: 'Aspyn Briez',
      swimIqScore: 993,
      highestCut: 'BB',
      readiness: 'Race ready',
      nextMeet: 'Time trial — 100 Fly SCY',
      powerIndexLine: '65 / 100 · Competitive',
      topTimes: ['100 Fly SCY · 1:12.00', '200 Fly LCM · 3:07.00'],
      latestTechniquePriorities: ['Hold a longer streamline'],
      generatedAtIso: '2026-08-01T12:00:00.000Z',
      powerIndexScore: 65,
      powerIndexLabel: 'Competitive',
      powerFactors: [
        LivingPassportPowerFactor(
          id: 'cuts',
          label: 'USA cuts',
          score: 70,
          weightPercent: 40,
        ),
      ],
      strongestEvent: '100 Fly SCY',
      currentFocus: 'Butterfly race pace',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LivingPassportPublicScreen(payload: payload),
      ),
    );

    expect(find.text('Living Passport'), findsOneWidget);
    expect(find.text('Aspyn Briez'), findsOneWidget);
    expect(find.textContaining('Built for coaches'), findsOneWidget);
    expect(find.text('Power Index breakdown'), findsOneWidget);
    expect(find.text('Signature times'), findsOneWidget);
    expect(find.textContaining('100 Fly SCY · 1:12.00'), findsOneWidget);
    expect(find.text('Technique priorities'), findsOneWidget);
    expect(find.textContaining('not the full private app'), findsOneWidget);
  });
}
