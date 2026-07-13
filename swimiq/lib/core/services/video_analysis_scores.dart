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
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  static String? technicalError(SwimVideoAnalysis analysis) {
    final raw = analysis.analysisJson?['gemini_error_raw']?.toString();
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    return null;
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
      'Android Studio does NOT connect to Gemini — you only need Node.js + the bat file below.\n\n'
      'Step 1: Supabase Dashboard → Edge Functions → Secrets → GEMINI_API_KEY (your AIza key).\n\n'
      'Step 2: On your PC, open the swimiq folder from git pull, double-click KARA-GEMINI-FIX-NOW.bat.\n\n'
      'Step 3: When it says SUCCESS, tap Test video server below — you should see "Video server ready".\n\n'
      'Step 4: Tap Analyze on this clip again (wait ~90s). You should see "Gemini — frame-by-frame video analysis".';

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
