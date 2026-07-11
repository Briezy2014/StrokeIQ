import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/video_analysis_score_summaries.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';

void main() {
  test('builds race readiness summary from quick pro and con', () {
    const analysis = SwimVideoAnalysis(
      swimmer: 'Aspyn',
      summary: 'test',
      strengths: 'test',
      improvements: 'test',
      techniqueScore: 62,
      paceScore: 70,
      overallScore: 68,
      analysisJson: {
        'quick_pro':
            '• Good breakout focus — you know when to take your first stroke after your underwater.',
        'quick_con':
            '• Start phase needs sharpening — tighten block setup and the first underwater push.',
      },
    );

    final summary = VideoAnalysisScoreSummaries.overall(analysis);
    expect(summary, contains('Race readiness'));
    expect(summary, contains('Going well:'));
    expect(summary, contains('Work on:'));
    expect(summary, contains('breakout'));
    expect(summary, contains('Start phase'));
  });

  test('uses stored Gemini summaries when present', () {
    const analysis = SwimVideoAnalysis(
      swimmer: 'Aspyn',
      summary: 'test',
      strengths: 'test',
      improvements: 'test',
      techniqueScore: 80,
      paceScore: 78,
      overallScore: 79,
      analysisJson: {
        'technique_summary':
            'Stroke mechanics — Going well: flat body line. Work on: head lift on breath.',
      },
    );

    expect(
      VideoAnalysisScoreSummaries.technique(analysis),
      contains('flat body position on the water'),
    );
  });
}
