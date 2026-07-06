import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_brand_typography.dart';
import 'package:swimiq/widgets/swimiq_logo.dart';

void main() {
  testWidgets('SwimIqTagline renders brand copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SwimIqTagline())),
    );
    expect(
      find.textContaining('Built in the Water'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Driven by Possibility'),
      findsOneWidget,
    );
  });

  testWidgets('SwimIqBrandMark shows SWIMIQ fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SwimIqBrandMark(size: 80)),
      ),
    );
    expect(find.textContaining('SWIM'), findsOneWidget);
    expect(find.textContaining('IQ'), findsOneWidget);
  });
}
