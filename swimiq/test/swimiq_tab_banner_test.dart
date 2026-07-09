import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/providers/app_providers.dart';
import 'package:swimiq/widgets/swimiq_tab_banner.dart';

void main() {
  testWidgets('SwimIqTabBanner shows per-tab quote and module chip', (tester) async {
    const swimmer = 'Aspyn';
    final expectedQuote = SwimIqTabBanner.quoteForTab(swimmer, HomeTab.videoLab);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwimIqTabBanner(tabIndex: HomeTab.videoLab, swimmer: swimmer),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Video Lab'), findsOneWidget);
    expect(find.text(expectedQuote), findsOneWidget);
  });

  test('moduleLabelForTab covers all six bottom-nav tabs', () {
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.dashboard), 'Dashboard');
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.personalBests), 'PBs');
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.trainingLog), 'Log');
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.goals), 'Goals');
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.videoLab), 'Video Lab');
    expect(SwimIqTabBanner.moduleLabelForTab(HomeTab.passport), 'Passport');
    expect(SwimIqTabBanner.tabModuleLabels.length, 6);
  });
}
