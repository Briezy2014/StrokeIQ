import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/theme/app_theme.dart';
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

  testWidgets('CoachingReportView shows hero, rhythm chart, and sections', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final results = AnalysisResults(
      jobId: 'job-1',
      status: 'completed',
      engineVersion: 'elite-0.9.0',
      stroke: const {'stroke': 'butterfly', 'distance_m': 50},
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
    expect(
      find.textContaining('Aspyn, on this 50 butterfly'),
      findsOneWidget,
    );
    expect(find.text('Race focus map'), findsOneWidget);
    expect(find.text('Stroke rhythm guide'), findsOneWidget);
    expect(find.text('Keep doing this'), findsOneWidget);
    expect(find.text('Fix this next'), findsOneWidget);
    expect(find.text('Next race'), findsOneWidget);
    expect(find.textContaining('0.3-0.8'), findsWidgets);
  });
}
