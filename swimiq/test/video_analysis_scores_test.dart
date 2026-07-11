import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/video_analysis_scores.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';

void main() {
  test('formats scores out of 100', () {
    expect(VideoAnalysisScores.formatScore(70), '70/100');
    expect(VideoAnalysisScores.clamp(140), 100);
  });

  test('legend differs for Gemini vs notes fallback', () {
    const gemini = SwimVideoAnalysis(
      swimmer: 'Aspyn',
      summary: 'test',
      strengths: 'test',
      improvements: 'test',
      techniqueScore: 80,
      paceScore: 78,
      overallScore: 79,
      analysisJson: {'engine': 'swimiq-v2-gemini'},
    );
    const notes = SwimVideoAnalysis(
      swimmer: 'Aspyn',
      summary: 'test',
      strengths: 'test',
      improvements: 'test',
      techniqueScore: 70,
      paceScore: 68,
      overallScore: 69,
      analysisJson: {'engine': 'swimiq-v1-notes'},
    );

    expect(VideoAnalysisScores.legend(gemini), contains('video'));
    expect(VideoAnalysisScores.legend(notes), contains('upload notes'));
    expect(VideoAnalysisScores.legend(notes), contains('MediaPipe'));
    expect(VideoAnalysisScores.fallbackReason(notes), isNull);
    expect(
      VideoAnalysisScores.fallbackReason(
        notes.copyWith(
          analysisJson: {
            'engine': 'swimiq-v1-notes',
            'gemini_fallback_reason': 'GEMINI_API_KEY is not configured',
          },
        ),
      ),
      contains('GEMINI_API_KEY'),
    );
  });
}
