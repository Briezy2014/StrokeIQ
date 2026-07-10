import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/theme/app_theme.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/data/models/video_models.dart';
import 'package:swimiq/providers/app_providers.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';
import 'package:swimiq/screens/home_screen.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';
import 'package:swimiq/widgets/swimiq_tab_banner.dart';

import 'support/motivational_standards_test_helper.dart';
import 'support/subscription_test_helper.dart';

SwimmerData? _auditData;

class _AuditSwimmerDataNotifier extends SwimmerDataNotifier {
  @override
  Future<SwimmerData?> build() async => _auditData;
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  setUp(() {
    _auditData = SwimmerData(
      raceLogs: [
        RaceLog(
          swimmer: 'Aspyn',
          event: '100 Butterfly',
          distance: 100,
          stroke: 'Butterfly',
          course: 'SCY',
          timeSeconds: 72,
          date: DateTime(2026, 6, 1),
        ),
      ],
      goals: [
        SwimGoal(
          swimmerName: 'Aspyn',
          event: '100 Butterfly',
          goalTime: 66,
          course: 'SCY',
          targetDate: DateTime(2026, 10, 1),
        ),
      ],
      meetResults: [
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Test Meet',
          event: '100 Butterfly',
          swimTime: 72,
          course: 'SCY',
          meetDate: DateTime(2026, 6, 1),
        ),
      ],
      profile: const SwimmerProfile(
        swimmerName: 'Aspyn',
        preferredName: 'Aspyn',
        team: 'COA',
      ),
      videos: [
        SwimVideo(
          id: 'video-1',
          swimmer: 'Aspyn',
          title: '50 Fly',
          storagePath: 'Aspyn/video.mov',
        ),
      ],
      usaStandards: testMotivationalCatalog.flatStandards,
      motivationalStandards: testMotivationalCatalog,
    );
  });

  Widget _homeHarness(int tabIndex) {
    return ProviderScope(
      overrides: [
        activeSwimmerProvider.overrideWith((ref) => 'Aspyn'),
        swimmerDataProvider.overrideWith(_AuditSwimmerDataNotifier.new),
        homeTabIndexProvider.overrideWith((ref) => tabIndex),
        ...subscriptionTestOverrides,
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  group('All home tabs audit', () {
    for (final entry in SwimIqTabBanner.tabModuleLabels.entries) {
      testWidgets('tab ${entry.key} (${entry.value}) shows banner chip and core content',
          (tester) async {
        await tester.pumpWidget(_homeHarness(entry.key));
        await tester.pumpAndSettle();

        expect(find.byType(SwimIqTabBanner), findsOneWidget);
        expect(find.text(entry.value), findsWidgets);
        final quote = SwimIqTabBanner.quoteForTab('Aspyn', entry.key);
        expect(find.text(quote), findsOneWidget);
        expect(find.textContaining('Updates build'), findsNothing);
        expect(find.byType(SwimIqCompactMark), findsNothing);
      });
    }

    testWidgets('Dashboard shows rope climb and cuts section', (tester) async {
      await tester.pumpWidget(_homeHarness(HomeTab.dashboard));
      await tester.pumpAndSettle();

      expect(find.text('Daily Rope Climb'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Choose your SwimIQ plan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose your SwimIQ plan'), findsOneWidget);
      expect(find.text('SwimIQ Basic'), findsOneWidget);
      expect(find.text('SwimIQ Pro'), findsOneWidget);
      expect(find.text('SwimIQ Elite'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Log meets'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Log meets'), findsOneWidget);
      expect(find.text('Cuts mix'), findsOneWidget);
    });

    testWidgets('Log tab shows training segment controls', (tester) async {
      await tester.pumpWidget(_homeHarness(HomeTab.trainingLog));
      await tester.pumpAndSettle();

      expect(find.text('Training & practices'), findsWidgets);
      expect(find.text('Meets & results'), findsOneWidget);
    });

    testWidgets('Passport tab shows hub links', (tester) async {
      await tester.pumpWidget(_homeHarness(HomeTab.passport));
      await tester.pumpAndSettle();

      expect(find.text('Athlete Passport'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('SwimDNA™'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('SwimDNA™'), findsOneWidget);
      expect(find.text('AI Coach'), findsWidgets);
    });
  });

  test('every HomeTab index has a banner label', () {
    expect(SwimIqTabBanner.hasBannerForTab(HomeTab.dashboard), isTrue);
    expect(SwimIqTabBanner.hasBannerForTab(HomeTab.personalBests), isTrue);
    expect(SwimIqTabBanner.hasBannerForTab(HomeTab.trainingLog), isTrue);
    expect(SwimIqTabBanner.hasBannerForTab(HomeTab.goals), isTrue);
    expect(SwimIqTabBanner.hasBannerForTab(HomeTab.videoLab), isTrue);
    expect(SwimIqTabBanner.hasBannerForTab(HomeTab.passport), isTrue);
    expect(SwimIqTabBanner.tabModuleLabels.length, 6);
  });
}
