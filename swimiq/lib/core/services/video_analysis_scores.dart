import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
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
    if (version.contains('sync-v9') ||
        version.contains('stream-v4') ||
        version.contains('stream-v5') ||
        version.contains('stream-v6') ||
        version.contains('stream-v7') ||
        version.contains('stream-v8')) {
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
    if (isObsoleteGemini15Error(analysis)) return true;
    final reason = analysis.analysisJson?['gemini_fallback_reason']?.toString();
    if (reason == null || reason.trim().isEmpty) return false;
    final version = analysis.analysisJson?['function_version']?.toString() ?? '';
    if (version.contains('sync-v9') ||
        version.contains('stream-v6') ||
        version.contains('stream-v7') ||
        version.contains('stream-v8')) {
      return false;
    }
    return true;
  }

  /// Old server errors mention gemini-1.5 — hide after sync-v9 / stream-v6+ deploy.
  static bool isObsoleteGemini15Error(SwimVideoAnalysis analysis) {
    final raw = analysis.analysisJson?['gemini_error_raw']?.toString() ?? '';
    final reason = analysis.analysisJson?['gemini_fallback_reason']?.toString() ?? '';
    final combined = '$raw $reason'.toLowerCase();
    if (!combined.contains('gemini-1.5') && !combined.contains('gemini-2.0')) {
      return false;
    }
    final savedVersion =
        analysis.analysisJson?['function_version']?.toString() ?? '';
    if (savedVersion.contains('sync-v9') ||
        savedVersion.contains('stream-v6') ||
        savedVersion.contains('stream-v7') ||
        savedVersion.contains('stream-v8')) {
      return false;
    }
    return true;
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
    // Raw backend detail stays in analysis JSON for support — never show it in UI.
    return null;
  }

  static String? serverReadyBanner(VideoAnalysisServerHealth? serverHealth) {
    if (!serverIsStreamReady(serverHealth)) return null;
    final version = serverHealth!.functionVersion ?? 'stream';
    if (version.contains('cloud')) {
      return 'AI coaching is ready. Upload a race clip and tap Analyze.';
    }
    return 'AI coaching is ready. Tap Analyze above to review this clip. '
        'Older orange messages below are from a previous attempt.';
  }

  /// Rewrites outdated/ops server errors into customer-safe copy.
  static String sanitizeStoredGeminiMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('too large') ||
        lower.contains('413') ||
        (lower.contains('payload') && lower.contains('large'))) {
      return 'This video file is too large for AI analysis. '
          'Even short 4K phone clips can exceed ${AppConstants.maxGeminiVideoMb} MB — '
          're-export at 720p under ${AppConstants.maxGeminiVideoMb} MB, then Analyze again.';
    }
    if (lower.contains('worker_resource_limit') ||
        lower.contains('status: 546') ||
        lower.contains('not having enough compute resources') ||
        lower.contains('delete gemini_model') ||
        lower.contains('gemini_model secret') ||
        lower.contains('gemini-1.5') ||
        lower.contains('server needs an update') ||
        lower.contains('redeploy') ||
        (lower.contains('gemini-2.0-flash') &&
            (lower.contains('retired') || lower.contains('limit: 0'))) ||
        lower.contains('.bat') ||
        lower.contains('gemini_api_key')) {
      return 'AI coaching is temporarily unavailable. '
          'Try a clip under 30 seconds, then tap Analyze again. '
          'If it keeps failing, email support@swimiqapp.com.';
    }
    if (lower.contains('high demand') ||
        lower.contains('503') ||
        lower.contains('is busy right now') ||
        (lower.contains('unavailable') &&
            !lower.contains('video analysis was unavailable') &&
            !lower.contains('gemini video analysis was unavailable'))) {
      return 'AI coaching is temporarily busy. Wait 1–2 minutes and tap Analyze again.';
    }
    if (lower.contains('.bat') ||
        lower.contains('127.0.0.1') ||
        lower.contains('supabase secrets')) {
      return 'Analysis is temporarily unavailable. Please try again shortly.';
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
      return 'Ready — tap Analyze above for AI coaching on this clip.';
    }
    return awaitingSummary;
  }

  static const awaitingSummary =
      'AI has not watched this clip yet — tap Analyze to generate coaching.';

  static const awaitingLegend =
      'Video not analyzed yet. Scores below are placeholders until AI coaching runs.';

  static String legendFor(
    SwimVideoAnalysis analysis, {
    VideoAnalysisServerHealth? serverHealth,
  }) {
    if (awaitingGeminiVideoRead(analysis, serverHealth: serverHealth)) {
      if (serverIsStreamReady(serverHealth) && hasStaleSavedFailure(analysis)) {
        return 'A previous attempt did not finish. Tap Analyze above for a fresh AI coaching report.';
      }
      return awaitingLegend;
    }
    if (analysis.isGeminiEngine) {
      return 'AI coach ratings from your video (0 = major limiters, 100 = elite D1-level execution).';
    }
    return 'Estimated ratings from your upload notes — not frame-by-frame video. '
        'Add race notes or tap Analyze for AI video coaching.';
  }

  static const deployStepsBody =
      'AI coaching is not ready for this clip yet.\n\n'
      '• Use a short race clip (about 30 seconds or less)\n'
      '• Keep the file under 25 MB when possible\n'
      '• Stay signed in and tap Analyze again\n\n'
      'If it still fails, email support@swimiqapp.com.';

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
