import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/coaching/race_blueprint.dart';
import 'package:swimiq/data/models/video_engine_v2/analysis_metric.dart';
import 'package:swimiq/data/models/video_engine_v2/analysis_results.dart';

void main() {
  test('RaceBlueprintBuilder creates start-to-wall phases for butterfly', () {
    final blueprint = RaceBlueprintBuilder.fromResults(
      results: const AnalysisResults(
        jobId: 'job-1',
        status: 'completed',
        engineVersion: 'elite',
        stroke: {'stroke': 'butterfly', 'distance_m': 50},
        video: {'duration_ms': 28000},
      ),
      stroke: 'Butterfly',
      recommendations: const [
        'Race cue: kick on entry, breathe late and low.',
        'First 15m: tight underwater dolphins.',
      ],
    );

    expect(blueprint.phases.length, 4);
    expect(blueprint.phases.first.label, 'Start / UW');
    expect(blueprint.phases.last.label, 'Finish');
    expect(blueprint.energyPoints.length, greaterThanOrEqualTo(6));
    expect(blueprint.durationMs, 28000);
    expect(blueprint.usesMeasuredTiming, isFalse);
    expect(blueprint.footer.toLowerCase(), contains('kick on entry'));
    expect(
      blueprint.phases[1].cue.toLowerCase(),
      anyOf(contains('tempo'), contains('break')),
    );
    final mid = blueprint.phases.firstWhere((p) => p.id == 'mid');
    expect(mid.cue.toLowerCase(), contains('kick on entry'));
    expect(blueprint.seekMsForFraction(0.5), 14000);
  });

  test('underwater phase timing marks measured blueprint segments', () {
    final blueprint = RaceBlueprintBuilder.fromResults(
      results: AnalysisResults(
        jobId: 'job-2',
        status: 'completed',
        engineVersion: 'elite',
        video: const {'duration_ms': 20000},
        phases: const [
          AnalysisPhase(
            name: 'underwater_phase',
            startMs: 0,
            endMs: 4200,
            confidence: 0.8,
          ),
        ],
      ),
      stroke: 'Freestyle',
      recommendations: const ['Quiet head into stroke.'],
    );

    expect(blueprint.usesMeasuredTiming, isTrue);
    expect(blueprint.phases.first.measured, isTrue);
    expect(blueprint.phases[1].seekMs, 4200);
    expect(blueprint.caption.toLowerCase(), contains('timing from your clip'));
  });

  test('late stroke-rate drop shapes a fading finish footer', () {
    final blueprint = RaceBlueprintBuilder.fromResults(
      results: const AnalysisResults(
        jobId: 'job-3',
        status: 'completed',
        engineVersion: 'elite',
        metrics: [
          AnalysisMetric(
            name: 'late_clip_stroke_rate_change',
            displayName: 'Late-clip stroke-rate change',
            value: -3.5,
            unit: 'cycles/min',
            confidenceLabel: 'medium',
            classification: 'measured',
          ),
        ],
      ),
      stroke: 'Butterfly',
      recommendations: const [],
    );

    expect(blueprint.finishFades, isTrue);
    expect(blueprint.footer.toLowerCase(), contains('finish'));
    final lastY = blueprint.energyPoints.last.y;
    final midY = blueprint.energyPoints[blueprint.energyPoints.length ~/ 2].y;
    expect(lastY, lessThan(midY + 0.05));
  });
}
