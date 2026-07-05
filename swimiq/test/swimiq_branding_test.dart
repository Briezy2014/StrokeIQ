import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('auth header shows one logo and tagline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwimIqAuthHeader(title: 'Welcome back'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqAuthHeader), findsOneWidget);
    expect(find.byType(SwimIqLogo), findsOneWidget);
    expect(find.byType(SwimIqWordmark), findsNothing);
    expect(find.byType(SwimIqHeroBanner), findsNothing);
    expect(find.text('Built in the Water. Driven by Possibility.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

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
