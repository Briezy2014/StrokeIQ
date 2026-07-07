import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hero banner uses single icon asset', (tester) async {
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

  test('branding uses only swimiq_icon.png', () {
    expect(SwimIqBranding.assetPath, 'assets/branding/swimiq_icon.png');
    expect(SwimIqBranding.assetCandidates, ['assets/branding/swimiq_icon.png']);
  });
}
