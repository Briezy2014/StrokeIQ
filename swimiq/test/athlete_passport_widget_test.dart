import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimiq/core/theme/app_theme.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/app_providers.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';
import 'package:swimiq/screens/athlete_passport/athlete_passport_v2_screen.dart';

import 'support/motivational_standards_test_helper.dart';

class _Harness extends SwimmerDataNotifier {
  _Harness(this.data);

  final SwimmerData data;

  @override
  Future<SwimmerData?> build() async => data;
}

SwimmerData _passportHarnessData(SwimmerProfile profile) {
  return SwimmerData(
    raceLogs: [
      RaceLog(
        swimmer: 'Aspyn',
        event: '50 Fly',
        distance: 50,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: 30,
        date: DateTime(2026, 6, 1),
      ),
    ],
    goals: [
      SwimGoal(
        swimmerName: 'Aspyn',
        event: '100 Fly',
        goalTime: 66,
        course: 'SCY',
        targetDate: DateTime(2026, 10, 1),
      ),
    ],
    meetResults: [
      MeetResult(
        swimmerName: 'Aspyn',
        meetName: 'Test Meet',
        event: '50 Fly',
        swimTime: 30,
        course: 'SCY',
        meetDate: DateTime(2026, 6, 1),
      ),
    ],
    profile: profile,
    motivationalStandards: testMotivationalCatalog,
  );
}

Future<void> _pumpPassport(
  WidgetTester tester,
  SwimmerProfile profile,
) async {
  await tester.binding.setSurfaceSize(const Size(1100, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeSwimmerProvider.overrideWith((ref) => 'Aspyn'),
        swimmerDataProvider.overrideWith(
          () => _Harness(_passportHarnessData(profile)),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: AthletePassportV2Screen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  group('Athlete Passport form fields', () {
    testWidgets('has no dropdowns and renders blank stroke fields', (tester) async {
      await _pumpPassport(
        tester,
        const SwimmerProfile(
          id: 4,
          swimmerName: 'Aspyn',
          preferredName: 'Aspyn',
          team: 'COA',
          coachName: 'Gunner Lehr',
          primaryStroke: '',
          secondaryStroke: '',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<dynamic>), findsNothing);
      expect(find.byType(DropdownButton<dynamic>), findsNothing);

      // Recruiting card shows the athlete name (not an account slug).
      expect(find.text('Aspyn'), findsWidgets);
      expect(find.text('Add website'), findsOneWidget);
      expect(find.text('Add email'), findsOneWidget);
      expect(find.text('Add phone'), findsOneWidget);

      expect(find.text('Athlete Passport™ Command Center'), findsOneWidget);
      expect(find.text('SwimDNA™'), findsOneWidget);
      expect(find.text('Race Intelligence™'), findsOneWidget);
      expect(find.text('AI Coach'), findsWidgets);
      expect(find.text('Coming Soon to Athlete Passport™'), findsNothing);
      expect(find.text('Coming Soon'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Athlete email'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Athlete email'), findsOneWidget);
      expect(find.text('Athlete phone'), findsOneWidget);
      expect(find.text('Athlete website'), findsOneWidget);
    });

    testWidgets('renders invalid saved strokes as text without crashing',
        (tester) async {
      await _pumpPassport(
        tester,
        const SwimmerProfile(
          id: 4,
          swimmerName: 'Aspyn',
          preferredName: 'Aspyn',
          primaryStroke: 'Invalid Stroke',
          secondaryStroke: 'Sprint Free',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<dynamic>), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Secondary Stroke'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
