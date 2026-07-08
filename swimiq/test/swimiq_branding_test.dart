import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hero banner shows logo or fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwimIqHeroBanner(height: 120),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqHeroBanner), findsOneWidget);
    expect(
      find.byType(Image).evaluate().isNotEmpty ||
          find.byType(CustomPaint).evaluate().isNotEmpty,
      isTrue,
    );
  });

  test('branding lists icon-only paths', () {
    expect(SwimIqBranding.iconCandidates, contains('assets/branding/swimiq_icon.png'));
    expect(SwimIqBranding.iconCandidates.length, lessThanOrEqualTo(4));
  });
}
