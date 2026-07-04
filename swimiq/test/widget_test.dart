import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/app.dart';

void main() {
  testWidgets('SwimIQ app renders splash screen', (tester) async {
    await tester.pumpWidget(const SwimIQApp());
    await tester.pump();

    expect(find.text('SwimIQ'), findsOneWidget);
    expect(find.text('Built in the Water. Driven by Possibility.'), findsOneWidget);
  });
}
