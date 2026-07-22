import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimiq/providers/app_providers.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';
import 'package:swimiq/screens/usa_standards/usa_standards_screen.dart';

import 'support/motivational_standards_test_helper.dart';
import 'support/subscription_test_helper.dart';

class _Harness extends SwimmerDataNotifier {
  @override
  Future<SwimmerData?> build() async => SwimmerData(
        raceLogs: const [],
        goals: const [],
        meetResults: const [],
        motivationalStandards: testMotivationalCatalog,
      );
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  testWidgets('USA Standards renders search field without pushed-route crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSwimmerProvider.overrideWith((ref) => 'Aspyn'),
          swimmerDataProvider.overrideWith(_Harness.new),
          ...subscriptionTestOverrides,
        ],
        child: const MaterialApp(
          home: UsaStandardsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('USA Standards'), findsWidgets);
  });
}
