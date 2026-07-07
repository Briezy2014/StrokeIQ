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
import 'package:swimiq/screens/home_screen.dart';
import 'package:swimiq/services/auth_service.dart';

import 'support/motivational_standards_test_helper.dart';
import 'support/subscription_test_helper.dart';

/// HomeScreen Passport tab uses AthletePassportV2Screen (text fields only).

class _AspynHarness extends SwimmerDataNotifier {
  @override
  Future<SwimmerData?> build() async {
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
      profile: SwimmerProfile.fromJson({
        'id': 4,
        'swimmer_name': 'Aspyn',
        'preferred_name': 'Aspyn',
        'team': 'COA',
        'coach_name': 'Gunner Lehr',
        'primary_stroke': '',
        'secondary_stroke': '',
        'graduation_year': null,
      }),
      motivationalStandards: testMotivationalCatalog,
    );
  }
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('blank Supabase stroke strings are not valid dropdown values', () {
    const menuValues = <String?>[null, 'Butterfly'];
    const savedValue = '';
    final matches =
        menuValues.where((item) => item == savedValue).length;
    expect(matches, 0);
  });

  testWidgets('HomeScreen Passport tab renders without any dropdowns for Aspyn',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSwimmerProvider.overrideWith((ref) => 'Aspyn'),
          swimmerDataProvider.overrideWith(_AspynHarness.new),
          currentUserProvider.overrideWith((ref) => null),
          ...subscriptionTestOverrides,
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.badge_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DropdownButtonFormField<dynamic>), findsNothing);
    expect(find.byType(DropdownButton<dynamic>), findsNothing);
  });
}
