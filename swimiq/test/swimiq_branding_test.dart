import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hero banner loads the shared logo asset', (tester) async {
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

  test('branding uses one logo file everywhere', () {
    expect(
      SwimIqBranding.logoCandidates,
      contains('assets/branding/swimiq_logo.png'),
    );
    expect(SwimIqBranding.iconCandidates, SwimIqBranding.logoCandidates);
    expect(SwimIqBranding.heroCandidates, SwimIqBranding.logoCandidates);
  });
}
