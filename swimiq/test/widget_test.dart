import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/app.dart';

void main() {
  testWidgets('SwimIQ app shows config error without credentials', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SwimIqApp()));
    await tester.pump();

    expect(find.text('Supabase is not configured'), findsOneWidget);
  });
}
