import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/video_analysis_scores.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';

void main() {
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

  final awaiting = SwimVideoAnalysis(
    swimmer: 'Aspyn',
    summary: 'test',
    strengths: 'test',
    improvements: 'test',
    techniqueScore: 66,
    paceScore: 62,
    overallScore: 64,
    analysisJson: {
      'engine': 'swimiq-v1-notes',
      'gemini_fallback_reason': 'Video analysis server needs an update',
    },
  );

  test('formats scores out of 100 for Gemini analyses', () {
    expect(VideoAnalysisScores.formatScore(gemini, 70), '70/100');
    expect(VideoAnalysisScores.clamp(140), 100);
  });

  test('shows dash scores while awaiting Gemini video read', () {
    expect(VideoAnalysisScores.awaitingGeminiVideoRead(awaiting), isTrue);
    expect(VideoAnalysisScores.formatScore(awaiting, 66), '—');
    expect(
      VideoAnalysisScores.overallSummary(awaiting),
      contains('has not watched'),
    );
    expect(VideoAnalysisScores.legendFor(awaiting), contains('not analyzed'));
  });

  test('legend differs for Gemini vs notes fallback', () {
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

    expect(VideoAnalysisScores.legendFor(gemini), contains('video'));
    expect(VideoAnalysisScores.legendFor(notes), contains('not analyzed'));
    expect(VideoAnalysisScores.fallbackReason(notes), isNull);
    expect(
      VideoAnalysisScores.fallbackReason(awaiting),
      contains('temporarily unavailable'),
    );
  });

  test('rewrites stale GEMINI_MODEL error saved from old server deploys', () {
    const stale =
        'Gemini model is retired (often gemini-1.5-flash in Supabase secrets). '
        'Delete GEMINI_MODEL secret in Supabase, then run KARA-GEMINI-FIX-NOW.bat';
    final rewritten = VideoAnalysisScores.sanitizeStoredGeminiMessage(stale);
    expect(rewritten, contains('temporarily unavailable'));
    expect(rewritten, isNot(contains('Delete GEMINI_MODEL')));
    expect(rewritten, isNot(contains('.bat')));
  });

  test('rewrites 503 high demand errors with retry guidance', () {
    const busy =
        'Gemini model "gemini-3.5-flash" is busy right now (Google high demand).';
    final rewritten = VideoAnalysisScores.sanitizeStoredGeminiMessage(busy);
    expect(rewritten, contains('brief hiccup'));
    expect(
      VideoAnalysisScores.isTransientCloudBusyError(busy),
      isTrue,
    );
    expect(
      VideoAnalysisScores.friendlyCloudAnalyzeError(busy),
      contains('brief hiccup'),
    );
  });

  test('does not treat generic unavailable as busy', () {
    const unavailable =
        'AI video analysis was unavailable — notes-based coaching was saved.';
    expect(
      VideoAnalysisScores.isTransientCloudBusyError(unavailable),
      isFalse,
    );
    expect(
      VideoAnalysisScores.friendlyCloudAnalyzeError(unavailable),
      isNot(contains('busy right now')),
    );
  });
}
