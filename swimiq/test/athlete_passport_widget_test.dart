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
  );
}

Future<void> _pumpPassport(
  WidgetTester tester,
  SwimmerProfile profile,
) async {
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

      await tester.scrollUntilVisible(
        find.text('Primary Stroke'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Dominant Hand'), findsOneWidget);
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
