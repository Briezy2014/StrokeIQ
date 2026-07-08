import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';
import 'package:swimiq/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login brand uses dark wordmark for white cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SwimIqLoginBrand(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqLoginBrand), findsOneWidget);
    expect(find.byType(SwimIqWordmark), findsOneWidget);
  });

  testWidgets('full lockup widget builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwimIqFullLockup(width: 200),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqFullLockup), findsOneWidget);
  });

  testWidgets('compact mark widget builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwimIqCompactMark(size: 48),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqCompactMark), findsOneWidget);
  });

  test('branding lists include lockup and mark paths', () {
    expect(
      SwimIqBranding.fullLockupCandidates,
      contains('assets/branding/swimiq_icon.png'),
    );
    expect(
      SwimIqBranding.fullLockupCandidates,
      contains('assets/branding/swimiq_logo.png'),
    );
    expect(
      SwimIqBranding.iconMarkCandidates,
      contains('assets/branding/swimiq_icon_mark.png'),
    );
    expect(AppConstants.brandIconSizePx, 512);
  });
}
