import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/coaching/elite_coach_report_mapper.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';
import 'package:swimiq/data/models/video_engine_v2/analysis_results.dart';

void main() {
  test('maps Elite coaching report for AI Coach without race notes', () {
    final analysis = EliteCoachReportMapper.fromResults(
      results: const AnalysisResults(
        jobId: 'job-elite-1',
        status: 'completed',
        engineVersion: 'elite-0.9.0',
        videoId: 'video-123',
        stroke: {'stroke': 'Butterfly', 'distance_m': 50, 'course': 'LCM'},
        report: AnalysisReport(
          summary: 'Aspyn, on this 50 butterfly: keep your rhythm.',
          strengths: ['Your stroke timing looks connected.'],
          priorityImprovements: [
            PriorityImprovement(
              title: 'Your second kick is late off the hand entry.',
              drills: ['Swim: 8× 25 kick-on-entry.'],
            ),
          ],
          raceRecommendations: [
            'Race cue: kick on entry, press the chest, breathe late and low.',
          ],
        ),
      ),
      swimmer: 'Aspyn',
    );

    expect(analysis, isNotNull);
    expect(analysis!.swimVideoId, 'video-123');
    expect(analysis.analysisEngine, EliteCoachReportMapper.engineName);
    expect(analysis.isLegacyRulesEngine, isFalse);
    expect(analysis.topPriorities, isNotEmpty);
    expect(analysis.topPriorities.first, contains('second kick'));
    expect(analysis.hasModernCoachingFormat, isTrue);
    expect(analysis.summary.toLowerCase(), contains('butterfly'));
    expect(analysis.analysisJson?['elite_job_id'], 'job-elite-1');
  });

  test('returns null when report is missing', () {
    final analysis = EliteCoachReportMapper.fromResults(
      results: const AnalysisResults(
        jobId: 'job-2',
        status: 'completed',
        engineVersion: 'elite-0.9.0',
        videoId: 'video-123',
      ),
      swimmer: 'Aspyn',
    );
    expect(analysis, isNull);
  });
}
