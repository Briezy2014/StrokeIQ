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
    expect(find.byType(SwimIqBrandedImage), findsOneWidget);
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

  test('branding uses short icon, banner, and mark names', () {
    expect(SwimIqBranding.iconAsset, 'assets/branding/icon.png');
    expect(SwimIqBranding.bannerAsset, 'assets/branding/banner.png');
    expect(SwimIqBranding.markAsset, 'assets/branding/mark.png');
    expect(
      SwimIqBranding.fullLockupCandidates.first,
      SwimIqBranding.iconAsset,
    );
    expect(
      SwimIqBranding.tabBannerCandidates.first,
      SwimIqBranding.bannerAsset,
    );
    expect(
      SwimIqBranding.compactCandidates.first,
      SwimIqBranding.markAsset,
    );
    expect(
      SwimIqBranding.fullLockupCandidates,
      contains('assets/branding/swimiq_icon.png'),
    );
    expect(
      SwimIqBranding.markCandidates,
      contains('assets/branding/SwimIQ_Mark.PNG'),
    );
    expect(AppConstants.brandIconAsset, SwimIqBranding.iconAsset);
    expect(AppConstants.brandIconSizePx, 512);
  });
}
