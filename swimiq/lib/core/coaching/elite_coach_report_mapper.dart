import '../../data/models/swim_video_analysis.dart';
import '../../data/models/video_engine_v2/analysis_results.dart';

/// Maps Elite Video Lab [AnalysisResults] into a [SwimVideoAnalysis]
/// so AI Coach / Passport can show the coaching report without race notes.
class EliteCoachReportMapper {
  const EliteCoachReportMapper._();

  static const engineName = 'swimiq-elite-v2';

  static SwimVideoAnalysis? fromResults({
    required AnalysisResults results,
    required String swimmer,
  }) {
    final report = results.report;
    if (!results.hasReport || report == null) return null;
    final videoId = results.videoId?.trim();
    if (videoId == null || videoId.isEmpty) return null;

    final strengths = report.strengths
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final improvements = report.priorityImprovements
        .map((p) => p.title.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final priorities = improvements.take(3).toList();
    final raceLines = report.raceRecommendations
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();
    final raceCue = raceLines.cast<String?>().firstWhere(
          (r) =>
              r!.toLowerCase().contains('race cue') ||
              r.toLowerCase().startsWith('first 15'),
          orElse: () => raceLines.isEmpty ? null : raceLines.first,
        );

    final quickPro = strengths.isNotEmpty
        ? strengths.first
        : 'Race timing and body line looked connected on this clip.';
    final quickCon = improvements.isNotEmpty
        ? improvements.first
        : (raceCue ?? 'Keep one clear race focus for the next swim.');

    final event = _eventLabel(results);
    final summary = (report.summary ?? '').trim().isNotEmpty
        ? report.summary!.trim()
        : [
            if (event != null) event,
            if (raceCue != null) raceCue,
          ].whereType<String>().join('\n');

    final overall = _overallScore(results, improvements.length);
    final technique = (overall + (improvements.isEmpty ? 6 : -4)).clamp(55, 96);
    final pace = (overall + (strengths.length >= 2 ? 4 : -2)).clamp(55, 96);

    return SwimVideoAnalysis(
      swimVideoId: videoId,
      swimmer: swimmer,
      summary: summary,
      strengths: strengths.join('\n'),
      improvements: improvements.join('\n'),
      techniqueScore: technique,
      paceScore: pace,
      overallScore: overall,
      createdAt: results.createdAt ?? DateTime.now(),
      analysisJson: {
        'engine': engineName,
        if (event != null) 'event': event,
        'top_3_priorities': priorities.isNotEmpty
            ? priorities
            : [
                if (raceCue != null) raceCue,
              ],
        'quick_pro': quickPro,
        'quick_con': quickCon,
        'sections': {
          'Quick pro from this video': quickPro,
          'Quick con from this video': quickCon,
          if (priorities.isNotEmpty)
            'Top 3 priorities for your next race': priorities.join('\n'),
        },
        'elite_job_id': results.jobId,
        'race_recommendations': report.raceRecommendations,
        'engine_version': results.engineVersion,
      },
    );
  }

  static String? _eventLabel(AnalysisResults results) {
    final stroke = (results.stroke?['stroke'] ??
            results.stroke?['type'] ??
            results.video?['stroke'] ??
            '')
        .toString()
        .trim();
    final distance = results.stroke?['distance_m'] ??
        results.video?['distance_m'] ??
        results.athlete?['distance_m'];
    final course = (results.stroke?['course'] ??
            results.video?['course'] ??
            results.athlete?['course'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    final parts = <String>[
      if (distance != null && '$distance'.trim().isNotEmpty) '$distance',
      if (stroke.isNotEmpty) stroke,
      if (course.isNotEmpty) course,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static int _overallScore(AnalysisResults results, int improvementCount) {
    // Soft score for Passport / AI Coach cards — not a fake sensor grade.
    var score = 84;
    if (results.isPartialSuccess) score -= 4;
    score -= (improvementCount * 4).clamp(0, 18);
    if (results.limitations.isNotEmpty) score -= 3;
    return score.clamp(60, 94);
  }
}
