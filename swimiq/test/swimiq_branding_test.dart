import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hero banner loads branded asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwimIqHeroBanner(height: 120),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqHeroBanner), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  test('branding lists include hero and icon paths', () {
    expect(SwimIqBranding.heroCandidates, contains('assets/branding/swimiq_hero.png'));
    expect(SwimIqBranding.iconCandidates, contains('assets/branding/swimiq_icon.png'));
  });
}
