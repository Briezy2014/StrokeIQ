import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swimiq_app/main.dart';

void main() {
  testWidgets('SwimIQ login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SwimIQApp()),
    );

    expect(find.text('Start SwimIQ'), findsOneWidget);
    expect(find.text('Built in the Water. Driven by Possibility.'), findsOneWidget);
  });
}
