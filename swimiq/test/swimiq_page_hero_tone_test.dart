import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/widgets/swimiq_page_hero.dart';

void main() {
  testWidgets('onPrimary hero uses white title text on blue banner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwimIqPageHero(
            title: 'AI Dryland Coach',
            subtitle: 'Dryland plan for Aspyn Briez',
            tone: SwimIqPageHeroTone.onPrimary,
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('AI Dryland Coach'));
    expect(title.style?.color, Colors.white);
    expect(title.style?.fontSize, 22);

    final subtitle = tester.widget<Text>(find.text('Dryland plan for Aspyn Briez'));
    expect(subtitle.style?.color?.a, greaterThan(0.8));
    expect(subtitle.style?.fontSize, 14);
  });
}
