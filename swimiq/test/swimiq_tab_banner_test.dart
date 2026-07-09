import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/providers/app_providers.dart';
import 'package:swimiq/widgets/swimiq_tab_banner.dart';

void main() {
  testWidgets('SwimIqTabBanner shows brand tagline and module chip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwimIqTabBanner(tabIndex: HomeTab.videoLab),
        ),
      ),
    );

    expect(find.textContaining('BUILT IN THE WATER'), findsOneWidget);
    expect(find.text('Video Lab'), findsOneWidget);
    expect(find.textContaining('BUILT IN THE WATER'), findsOneWidget);
  });

  test('moduleLabelForTab includes dashboard and other tabs', () {
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.dashboard), 'Dashboard');
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.goals), 'Goals');
  });
}
