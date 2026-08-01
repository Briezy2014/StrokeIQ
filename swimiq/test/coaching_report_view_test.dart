import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/theme/app_theme.dart';
import 'package:swimiq/data/models/video_engine_v2/analysis_metric.dart';
import 'package:swimiq/data/models/video_engine_v2/analysis_results.dart';
import 'package:swimiq/widgets/coaching_report_view.dart';

void main() {
  test('personalizeSummary replaces bare you with athlete name', () {
    expect(
      CoachingReportView.personalizeSummary(
        'you, on this 50 butterfly: keep your rhythm',
        'Aspyn',
      ),
      'Aspyn, on this 50 butterfly: keep your rhythm',
    );
  });

  testWidgets('CoachingReportView shows Race Blueprint for butterfly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final results = AnalysisResults(
      jobId: 'job-1',
      status: 'completed',
      engineVersion: 'elite-0.9.0',
      // Missing stroke map — must infer Butterfly from the summary.
      stroke: const {'distance_m': 50},
      video: const {'duration_ms': 26000},
      metrics: const [
        AnalysisMetric(
          name: 'swimmer_visibility_coverage',
          displayName: 'Swimmer visibility coverage',
          value: 1,
          unit: 'fraction',
        ),
        AnalysisMetric(
          name: 'frames_analyzed',
          displayName: 'Frames analyzed',
          value: 57,
          unit: 'frames',
        ),
      ],
      report: const AnalysisReport(
        summary: 'you, on this 50 butterfly: keep your rhythm and body line.',
        strengths: [
          'Your stroke timing looks connected.',
        ],
        priorityImprovements: [
          PriorityImprovement(
            title: 'Your hips drop when you breathe.',
            drills: ['Dryland: hollow-body holds.'],
          ),
        ],
        raceRecommendations: [
          'Race cue: kick on entry, press the chest, breathe late and low.',
          'First 15m: tight underwater dolphins.',
          'many age-group 50 fly swimmers drop about 0.3-0.8 seconds - that\'s your potential.',
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: CoachingReportView(
            results: results,
            athleteName: 'Aspyn',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aspyn'), findsWidgets);
    expect(find.textContaining('Butterfly'), findsWidgets);
    expect(
      find.textContaining('Aspyn, on this 50 butterfly'),
      findsOneWidget,
    );
    expect(find.text('Race Blueprint'), findsOneWidget);
    expect(find.textContaining('Performance energy curve'), findsOneWidget);
    expect(find.text('RACE SCAN'), findsOneWidget);
    expect(find.text('Phone coaching'), findsOneWidget);
    expect(find.textContaining('Where time can still be found'), findsWidgets);
    expect(find.textContaining('phone race video'), findsNothing);
    expect(find.textContaining('parents & coaches'), findsNothing);
    expect(find.textContaining('Effort map for phone'), findsNothing);
    expect(find.text('Breathing'), findsOneWidget);
    expect(find.textContaining('RACE IQ'), findsOneWidget);
    expect(find.text('Start / UW'), findsOneWidget);
    expect(find.text('Breakout'), findsWidgets);
    expect(find.text('Mid-race'), findsOneWidget);
    expect(find.text('Finish'), findsWidgets);
    expect(find.text('Stroke rhythm guide'), findsNothing);
    expect(find.text('Race focus map'), findsNothing);
    expect(find.textContaining('Butterfly rhythm model'), findsNothing);
    expect(find.text('Race snapshot'), findsNothing);
    expect(find.textContaining('Swimmer visibility'), findsNothing);
    expect(find.textContaining('Frames analyzed'), findsNothing);
    expect(find.text('Keep doing this'), findsOneWidget);
    expect(find.text('Fix this next'), findsOneWidget);
    expect(find.text('Next race'), findsOneWidget);
    expect(find.textContaining('0.3–0.8'), findsWidgets);

    await tester.ensureVisible(find.text('Breathing'));
    await tester.tap(find.text('Breathing'));
    await tester.pumpAndSettle();
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('Swim practice'), findsOneWidget);
    expect(find.text('Dryland'), findsWidgets);
  });
}
