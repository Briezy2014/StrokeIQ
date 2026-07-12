import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/ai_swim_analysis_service.dart';
import 'package:swimiq/core/services/video_analysis_score_summaries.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';
import 'package:swimiq/data/models/video_models.dart';

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
            '• Work on your start — eyes slightly down or out before the call, tighten on "take your marks," then explode on the beep into your streamline underwater.',
      },
    );

    final summary = VideoAnalysisScoreSummaries.overall(analysis);
    expect(summary, contains('Race readiness'));
    expect(summary, contains('Going well:'));
    expect(summary, contains('Work on:'));
    expect(summary, contains('breakout'));
    expect(summary, contains('take your marks'));
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

  test('empty notes use event coaching not upload placeholders', () {
    const video = SwimVideo(
      swimmer: 'Aspyn',
      storagePath: 'Aspyn/video.mov',
      title: '50 Fly',
      stroke: 'Butterfly',
      distance: '50',
      course: 'LCM',
    );
    final analysis = AiSwimAnalysisService().analyze(
      video: video,
      raceLogs: const [],
      goals: const [],
    );

    final overall = VideoAnalysisScoreSummaries.overall(analysis);
    final technique = VideoAnalysisScoreSummaries.technique(analysis);

    expect(overall, isNot(contains('Video uploaded')));
    expect(overall, isNot(contains('No upload notes')));
    expect(overall, contains('50 Butterfly LCM'));
    expect(technique, contains('hips up'));
    expect(analysis.analysisJson?['quick_con'], isNot(contains('cannot infer')));
  });
}
