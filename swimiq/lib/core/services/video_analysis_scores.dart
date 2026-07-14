import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../data/models/swim_video_analysis.dart';
import 'video_analysis_presenter.dart';
import 'video_analysis_score_summaries.dart';

/// Labels and copy for Video Lab AI score chips.
abstract final class VideoAnalysisScores {
  static const maxScore = 100;

  static const overallTitle = 'Overall';
  static const techniqueTitle = 'Technique';
  static const paceTitle = 'Pace';

  static String? fallbackReason(SwimVideoAnalysis analysis) {
    final raw = analysis.analysisJson?['gemini_fallback_reason']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return sanitizeStoredGeminiMessage(raw.trim());
  }

  static String? technicalError(SwimVideoAnalysis analysis) {
    final raw = analysis.analysisJson?['gemini_error_raw']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return sanitizeStoredGeminiMessage(raw.trim());
  }

  /// Rewrites outdated server errors saved from older deploys (e.g. bogus GEMINI_MODEL advice).
  static String sanitizeStoredGeminiMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('worker_resource_limit') ||
        lower.contains('status: 546') ||
        lower.contains('not having enough compute resources')) {
      return 'Your video server is OUT OF DATE or the clip is too large. '
          'Run KARA-GEMINI-FIX-NOW.bat on your PC (deploys streaming server v5), '
          'then trim clips to under 30 seconds / 25 MB and tap Analyze again. '
          'You do NOT need Android Studio or a new API key unless diagnosis says so.';
    }
    if (lower.contains('delete gemini_model') ||
        lower.contains('gemini_model secret') ||
        (lower.contains('model retired') && lower.contains('gemini-1.5'))) {
      return 'This error is from an old server version — you do NOT need a GEMINI_MODEL secret. '
          'Only GEMINI_API_KEY in Supabase. Run KARA-GEMINI-FIX-NOW.bat, wait 2 minutes, '
          'then tap Analyze again.';
    }
    if (lower.contains('gemini-1.5-flash') || lower.contains('gemini-1.5-pro')) {
      return 'Your server tried retired gemini-1.5. Run KARA-GEMINI-FIX-NOW.bat, '
          'wait 2 minutes, tap Analyze again (only GEMINI_API_KEY needed in Supabase).';
    }
    if (lower.contains('high demand') ||
        lower.contains('503') ||
        lower.contains('is busy right now') ||
        (lower.contains('unavailable') &&
            !lower.contains('video analysis was unavailable') &&
            !lower.contains('gemini video analysis was unavailable'))) {
      return 'Google Gemini is temporarily busy. Wait 1-2 minutes and tap Analyze again — '
          'the server tries multiple models with automatic retries.';
    }
    if (lower.contains('gemini-2.0-flash') &&
        (lower.contains('retired') || lower.contains('limit: 0'))) {
      return 'Google retired gemini-2.0-flash. Run KARA-GEMINI-FIX-NOW.bat to deploy the '
          'auto-model server, wait 2 minutes, then tap Analyze again.';
    }
    return raw;
  }

  /// True when Gemini did not watch the clip — do not show fake video-specific scores.
  static bool awaitingGeminiVideoRead(SwimVideoAnalysis analysis) {
    if (analysis.isGeminiEngine) return false;
    return fallbackReason(analysis) != null || analysis.isNotesDriven;
  }

  static const awaitingScoreLabel = '—';

  static const awaitingSummary =
      'Gemini has not watched this clip yet — complete server setup, then tap Analyze again.';

  static const awaitingLegend =
      'Video not analyzed yet. Scores and coaching below are placeholders until Gemini runs on your server.';

  static const deployStepsBody =
      'You do NOT need Android Studio. API key is from aistudio.google.com/apikey '
      '(not Android Studio).\n\n'
      'Step 1: FIX-VIDEO-DATABASE.bat or paste SQL in Supabase (once).\n\n'
      'Step 2: GEMINI_API_KEY in Supabase secrets only — no GEMINI_MODEL.\n\n'
      'Step 3: KARA-GEMINI-FIX-NOW.bat — must show server v5 after deploy.\n\n'
      'Step 4: KARA-WHY-GEMINI-FAILS.bat if Analyze still fails.\n\n'
      'Step 5: Tap Analyze again — clips under 25 MB / ~30 sec work best on web.';

  static String overallSummary(SwimVideoAnalysis analysis) {
    if (awaitingGeminiVideoRead(analysis)) return awaitingSummary;
    return VideoAnalysisScoreSummaries.overall(analysis);
  }

  static String techniqueSummary(SwimVideoAnalysis analysis) {
    if (awaitingGeminiVideoRead(analysis)) return awaitingSummary;
    return VideoAnalysisScoreSummaries.technique(analysis);
  }

  static String paceSummary(SwimVideoAnalysis analysis) {
    if (awaitingGeminiVideoRead(analysis)) return awaitingSummary;
    return VideoAnalysisScoreSummaries.pace(analysis);
  }

  static String legend(SwimVideoAnalysis analysis) {
    if (awaitingGeminiVideoRead(analysis)) return awaitingLegend;
    if (analysis.isGeminiEngine) {
      return 'AI coach ratings from your video (0 = major limiters, 100 = elite D1-level execution).';
    }
    return 'Estimated ratings from your upload notes — not frame-by-frame video. '
        'Add upload notes (start, strokes, finish) or deploy Gemini for video scores.';
  }

  static String? pipelineNote(SwimVideoAnalysis analysis) {
    if (analysis.isGeminiEngine) return null;
    if (awaitingGeminiVideoRead(analysis)) {
      return 'Until Gemini runs, coaching cannot match your footage. Follow the steps in the orange banner.';
    }
    if (analysis.hasPoseMetrics) {
      return 'MediaPipe body-line data was captured, but Gemini could not watch the '
          'full video — ratings below are from your notes plus pose estimates.';
    }
    return null;
  }

  static String formatScore(SwimVideoAnalysis analysis, int value) {
    if (awaitingGeminiVideoRead(analysis)) return awaitingScoreLabel;
    return '${clamp(value)}/$maxScore';
  }

  static Color scoreColor(SwimVideoAnalysis analysis, int value) {
    if (awaitingGeminiVideoRead(analysis)) return Colors.grey.shade500;
    return scoreColorForValue(value);
  }

  static Color scoreColorForValue(int value) {
    if (value >= 85) return const Color(0xFF16A34A);
    if (value >= 70) return AppColors.primary;
    if (value >= 55) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }

  static int clamp(int value) => value.clamp(0, maxScore);
}
