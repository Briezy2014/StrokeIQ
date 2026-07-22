import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_branding.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';
import 'package:swimiq/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login brand shows square icon slot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(backgroundColor: Colors.white, body: SwimIqLoginBrand()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqLoginBrand), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('full lockup widget builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SwimIqFullLockup(width: 200))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqFullLockup), findsOneWidget);
  });

  testWidgets('compact mark widget builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SwimIqCompactMark(size: 48))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwimIqCompactMark), findsOneWidget);
  });

  test('login uses icon.png first', () {
    expect(SwimIqBranding.loginIconCandidates.first, SwimIqBranding.iconAsset);
    expect(SwimIqBranding.compactCandidates.first, SwimIqBranding.markAsset);
    expect(AppConstants.brandIconAsset, SwimIqBranding.iconAsset);
    expect(AppConstants.brandLogoAsset, 'assets/branding/logo.png');
    expect(AppConstants.brandIconSizePx, 512);
  });

  test('logo.png mirrors icon.png for brand folder naming', () {
    final icon = File('assets/branding/icon.png');
    final logo = File('assets/branding/logo.png');
    expect(icon.existsSync(), isTrue, reason: 'login asset missing');
    expect(logo.existsSync(), isTrue, reason: 'brand kit mirror missing');
    expect(
      icon.readAsBytesSync(),
      logo.readAsBytesSync(),
      reason:
          'icon.png and logo.png must be identical — login reads icon.png only',
    );
  });
}
