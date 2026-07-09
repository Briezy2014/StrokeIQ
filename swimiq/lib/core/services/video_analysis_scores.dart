import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../data/models/swim_video_analysis.dart';
import 'video_analysis_presenter.dart';

/// Labels and copy for Video Lab AI score chips.
abstract final class VideoAnalysisScores {
  static const maxScore = 100;

  static const overallTitle = 'Overall';
  static const techniqueTitle = 'Technique';
  static const paceTitle = 'Pace';

  static const overallHint =
      'Race readiness — how complete and competitive this swim looked.';
  static const techniqueHint =
      'Stroke mechanics — body line, catch, kick, breathing, turns.';
  static const paceHint =
      'Tempo & rhythm — speed management from start to finish.';

  static String legend(SwimVideoAnalysis analysis) {
    if (analysis.isGeminiEngine) {
      return 'AI coach ratings from your video (0 = major limiters, 100 = elite D1-level execution).';
    }
    return 'Estimated ratings from your upload notes — not frame-by-frame video. '
        'Re-run after Gemini is configured for true video scores.';
  }

  static String? fallbackReason(SwimVideoAnalysis analysis) {
    final raw = analysis.analysisJson?['gemini_fallback_reason']?.toString();
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  static int clamp(int value) => value.clamp(0, maxScore);

  static String formatScore(int value) => '${clamp(value)}/$maxScore';

  static Color scoreColor(int value) {
    if (value >= 85) return const Color(0xFF16A34A);
    if (value >= 70) return AppColors.primary;
    if (value >= 55) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }
}
