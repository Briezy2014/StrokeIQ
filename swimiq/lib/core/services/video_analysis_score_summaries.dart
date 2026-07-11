import '../../data/models/swim_video_analysis.dart';
import '../utils/youth_friendly_analysis.dart';
import 'video_analysis_presenter.dart';

/// Builds kid-friendly summaries under Overall / Technique / Pace score tiles.
abstract final class VideoAnalysisScoreSummaries {
  static String overall(SwimVideoAnalysis analysis) =>
      _resolve(analysis, 'overall_summary', 'Race readiness', analysis.overallScore);

  static String technique(SwimVideoAnalysis analysis) =>
      _resolve(
        analysis,
        'technique_summary',
        'Stroke mechanics',
        analysis.techniqueScore,
      );

  static String pace(SwimVideoAnalysis analysis) =>
      _resolve(analysis, 'pace_summary', 'Tempo and rhythm', analysis.paceScore);

  static String _resolve(
    SwimVideoAnalysis analysis,
    String jsonKey,
    String categoryLabel,
    int score,
  ) {
    final stored = analysis.analysisJson?[jsonKey]?.toString().trim();
    if (stored != null && stored.isNotEmpty) {
      final plain = YouthFriendlyAnalysis.plainLanguage(stored);
      if (plain.toLowerCase().startsWith(categoryLabel.toLowerCase())) {
        return plain;
      }
      return _format(categoryLabel, plain);
    }

    final pro = _insightText(analysis, isStrength: true);
    final con = _insightText(analysis, isStrength: false);
    return _compose(categoryLabel, score, pro, con);
  }

  static String _insightText(
    SwimVideoAnalysis analysis, {
    required bool isStrength,
  }) {
    final sections = VideoAnalysisPresenter.visibleSections(analysis);
    final key = isStrength
        ? 'Quick pro from this video'
        : 'Quick con from this video';
    final fromSection = sections[key]?.trim();
    if (fromSection != null && fromSection.isNotEmpty) {
      return YouthFriendlyAnalysis.plainLanguage(_stripBullet(fromSection));
    }

    final jsonKey = isStrength ? 'quick_pro' : 'quick_con';
    final raw = analysis.analysisJson?[jsonKey]?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return YouthFriendlyAnalysis.plainLanguage(_stripBullet(raw));
    }
    return '';
  }

  static String _compose(
    String categoryLabel,
    int score,
    String good,
    String workOn,
  ) {
    final goingWell = good.isNotEmpty
        ? good
        : _defaultGoingWell(categoryLabel, score);
    final nextFocus = workOn.isNotEmpty
        ? workOn
        : _defaultWorkOn(categoryLabel, score);

    return _format(
      categoryLabel,
      'Going well: $goingWell Work on: $nextFocus',
    );
  }

  static String _format(String categoryLabel, String body) {
    return '$categoryLabel — $body';
  }

  static String _stripBullet(String text) {
    return text
        .replaceFirst(RegExp(r'^[•\-\*]\s*'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
  }

  static String _defaultGoingWell(String category, int score) {
    if (score >= 80) {
      return switch (category) {
        'Race readiness' =>
          'you looked competitive and race-ready for most of this swim.',
        'Stroke mechanics' =>
          'your stroke looked clean and controlled in several phases.',
        _ => 'your tempo stayed steady for much of the race.',
      };
    }
    if (score >= 65) {
      return switch (category) {
        'Race readiness' => 'you stayed in the race and kept fighting to the end.',
        'Stroke mechanics' => 'parts of your stroke are already working — build on those.',
        _ => 'you held your rhythm in the middle of the race.',
      };
    }
    return switch (category) {
      'Race readiness' => 'you got the race on video — that is the first step to improving.',
      'Stroke mechanics' => 'you are building awareness of how your stroke feels.',
      _ => 'you are learning how your race pace feels from start to finish.',
    };
  }

  static String _defaultWorkOn(String category, int score) {
    if (score >= 80) {
      return switch (category) {
        'Race readiness' => 'tiny race details — start, turns, and finish touch.',
        'Stroke mechanics' => 'one small technique detail each lap.',
        _ => 'holding the same tempo on the last length.',
      };
    }
    if (score >= 65) {
      return switch (category) {
        'Race readiness' =>
          'start reaction, underwater, and a strong finish at the wall.',
        'Stroke mechanics' =>
          'body line, breathing, and keeping your pull and kick connected.',
        _ => 'not letting your tempo rush or fade late in the race.',
      };
    }
    return switch (category) {
      'Race readiness' =>
        'block setup, underwater, and finishing with a complete last stroke.',
      'Stroke mechanics' =>
        'hips up, head down, and a steady kick while you pull.',
      _ => 'even tempo from the start through the middle and finish.',
    };
  }
}
