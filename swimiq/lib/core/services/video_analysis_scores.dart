import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../data/models/swim_video_analysis.dart';
import 'gemini_swim_analysis_service.dart';
import 'video_analysis_score_summaries.dart';

/// Labels and copy for Video Lab AI score chips.
abstract final class VideoAnalysisScores {
  static const maxScore = 100;

  static const overallTitle = 'Overall';
  static const techniqueTitle = 'Technique';
  static const paceTitle = 'Pace';

  static bool serverIsStreamReady(VideoAnalysisServerHealth? health) {
    if (health == null) return false;
    final version = health.functionVersion ?? '';
    if (version.contains('stream-v4') || version.contains('stream-v5')) {
      return true;
    }
    return health.ok;
  }

  /// Failed Gemini attempts saved to DB — hide and auto-clear these.
  static bool isPlaceholderAnalysis(SwimVideoAnalysis analysis) {
    if (analysis.isGeminiEngine) return false;
    if (hasStaleSavedFailure(analysis)) return true;
    final raw = analysis.analysisJson?['gemini_error_raw']?.toString();
    return raw != null && raw.trim().isNotEmpty;
  }

  /// Saved failure from a previous Analyze attempt (not a live error).
  static bool hasStaleSavedFailure(SwimVideoAnalysis analysis) {
    if (analysis.isGeminiEngine) return false;
    final reason = analysis.analysisJson?['gemini_fallback_reason']?.toString();
    return reason != null && reason.trim().isNotEmpty;
  }

  static String? fallbackReason(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    final serverReady = serverIsStreamReady(serverHealth);
    if (serverReady && hasStaleSavedFailure(analysis)) {
      return null;
    }
    final raw = analysis.analysisJson?['gemini_fallback_reason']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return sanitizeStoredGeminiMessage(raw.trim());
  }

  static String? technicalError(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (serverIsStreamReady(serverHealth) && hasStaleSavedFailure(analysis)) {
      return null;
    }
    final raw = analysis.analysisJson?['gemini_error_raw']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return sanitizeStoredGeminiMessage(raw.trim());
  }

  static String? serverReadyBanner(VideoAnalysisServerHealth? serverHealth) {
    if (!serverIsStreamReady(serverHealth)) return null;
    final version = serverHealth!.functionVersion ?? 'stream';
    return 'Video server is ready ($version). Tap Analyze again — Gemini watches '
        'your clip and MediaPipe scans body lines. Any orange errors below are '
        'from an old attempt before the server was fixed.';
  }

  /// Rewrites outdated server errors saved from older deploys (e.g. bogus GEMINI_MODEL advice).
  static String sanitizeStoredGeminiMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('worker_resource_limit') ||
        lower.contains('status: 546') ||
        lower.contains('not having enough compute resources')) {
      return 'Previous attempt failed (server was out of date). '
          'If KARA-WHY-GEMINI-FAILS.bat shows stream-v5, tap Analyze again. '
          'Use clips under 30 seconds / 25 MB.';
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
  static bool awaitingGeminiVideoRead(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (analysis.isGeminiEngine) return false;
    return hasStaleSavedFailure(analysis) ||
        analysis.isNotesDriven ||
        fallbackReason(analysis, serverHealth: serverHealth) != null;
  }

  static const awaitingScoreLabel = '—';

  static String awaitingSummaryFor(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (serverIsStreamReady(serverHealth) && hasStaleSavedFailure(analysis)) {
      return 'Ready — tap Analyze again. Gemini will watch this clip; MediaPipe '
          'will scan body lines in Chrome (rope/non-pool clips may skip pose).';
    }
    return awaitingSummary;
  }

  static const awaitingSummary =
      'Gemini has not watched this clip yet — complete server setup, then tap Analyze again.';

  static const awaitingLegend =
      'Video not analyzed yet. Scores and coaching below are placeholders until Gemini runs on your server.';

  static String legendFor(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      if (serverIsStreamReady(serverHealth) && hasStaleSavedFailure(analysis)) {
        return 'Server is fixed — old errors are saved from a previous try. '
            'Tap Analyze again for real Gemini + MediaPipe results.';
      }
      return awaitingLegend;
    }
    if (analysis.isGeminiEngine) {
      return 'AI coach ratings from your video (0 = major limiters, 100 = elite D1-level execution).';
    }
    return 'Estimated ratings from your upload notes — not frame-by-frame video. '
        'Add upload notes (start, strokes, finish) or deploy Gemini for video scores.';
  }

  static const deployStepsBody =
      'You do NOT need Android Studio. API key is from aistudio.google.com/apikey '
      '(not Android Studio).\n\n'
      'Step 1: FIX-VIDEO-DATABASE.bat or paste SQL in Supabase (once).\n\n'
      'Step 2: GEMINI_API_KEY in Supabase secrets only — no GEMINI_MODEL.\n\n'
      'Step 3: KARA-GEMINI-FIX-NOW.bat — must show server v5 after deploy.\n\n'
      'Step 4: KARA-WHY-GEMINI-FAILS.bat if Analyze still fails.\n\n'
      'Step 5: Tap Analyze again — clips under 25 MB / ~30 sec work best on web.';

  static String overallSummary(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      return awaitingSummaryFor(analysis, serverHealth: serverHealth);
    }
    return VideoAnalysisScoreSummaries.overall(analysis);
  }

  static String techniqueSummary(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      return awaitingSummaryFor(analysis, serverHealth: serverHealth);
    }
    return VideoAnalysisScoreSummaries.technique(analysis);
  }

  static String paceSummary(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      return awaitingSummaryFor(analysis, serverHealth: serverHealth);
    }
    return VideoAnalysisScoreSummaries.pace(analysis);
  }

  static String? pipelineNote(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (analysis.isGeminiEngine) return null;
    if (serverIsStreamReady(serverHealth) && hasStaleSavedFailure(analysis)) {
      return null;
    }
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      return 'Until Gemini runs, coaching cannot match your footage. Follow the steps in the orange banner.';
    }
    if (analysis.hasPoseMetrics) {
      return 'MediaPipe body-line data was captured, but Gemini could not watch the '
          'full video — ratings below are from your notes plus pose estimates.';
    }
    return null;
  }

  static String formatScore(
    SwimVideoAnalysis analysis,
    int value, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      return awaitingScoreLabel;
    }
    return '${clamp(value)}/$maxScore';
  }

  static Color scoreColor(
    SwimVideoAnalysis analysis,
    int value, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      return Colors.grey.shade500;
    }
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
