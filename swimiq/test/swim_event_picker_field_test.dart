import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_event_options.dart';
import 'package:swimiq/widgets/swim_event_picker_field.dart';

void main() {
  const options = [
    SwimEventOption(
      distance: 50,
      stroke: 'Butterfly',
      course: 'LCM',
      label: '50 Butterfly',
    ),
    SwimEventOption(
      distance: 100,
      stroke: 'Butterfly',
      course: 'LCM',
      label: '100 Butterfly',
    ),
    SwimEventOption(
      distance: 200,
      stroke: 'Butterfly',
      course: 'LCM',
      label: '200 Butterfly',
    ),
  ];

  test('SwimEventOption equality is by distance/stroke/course', () {
    const a = SwimEventOption(
      distance: 50,
      stroke: 'Butterfly',
      course: 'LCM',
      label: '50 Butterfly',
    );
    const b = SwimEventOption(
      distance: 50,
      stroke: 'Butterfly',
      course: 'LCM',
      label: '50 Fly',
    );
    expect(a, equals(b));
  });

  testWidgets('event picker field opens searchable list and selects', (
    tester,
  ) async {
    SwimEventOption? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwimEventPickerField(
            options: options,
            selected: selected,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Tap to choose event'), findsOneWidget);
    await tester.tap(find.text('Tap to choose event'));
    await tester.pumpAndSettle();

    expect(find.text('Select event'), findsOneWidget);
    expect(find.text('50 Butterfly'), findsOneWidget);
    await tester.tap(find.text('200 Butterfly'));
    await tester.pumpAndSettle();

    expect(selected?.label, '200 Butterfly');
  });
}
