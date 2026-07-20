import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';

enum PassportHubDestination {
  aiCoach,
  videoLab,
  usaStandards,
  raceIntelligence,
  swimDna,
  recruitingCenter,
}

class PassportAiRecommendation {
  const PassportAiRecommendation({
    required this.headline,
    required this.detail,
    required this.actionLabel,
    required this.destination,
    this.suggestedEvent,
    this.priorities = const [],
    this.engineLabel =
        'SwimIQ AI Coach · powered by your race videos and meet data',
  });

  final String headline;
  final String detail;
  final String actionLabel;
  final PassportHubDestination destination;
  final String? suggestedEvent;
  final List<String> priorities;
  final String engineLabel;

  static PassportAiRecommendation build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final snapshot = data.passportSnapshot(swimmer);
    final videos = data.userFacingVideos;
    final analyses = data.userFacingVideoAnalyses;
    final unanalyzed = _unanalyzedVideos(videos, analyses);

    // Prefer an existing coaching report so AI Coach never looks empty
    // after Elite analysis already succeeded.
    if (analyses.isNotEmpty) {
      final latest = _latestAnalysis(analyses);
      final priorities = latest?.topPriorities ?? const <String>[];
      final event =
          snapshot.latestAnalysisEvent ??
          latest?.analysisJson?['event']?.toString();
      final detail = priorities.isNotEmpty
          ? priorities.take(3).join('\n')
          : (snapshot.nextFocus.trim().isNotEmpty
              ? snapshot.nextFocus
              : (latest?.summary.trim().isNotEmpty == true
                  ? latest!.summary.trim()
                  : 'Open your latest coaching report for race cues and drills.'));

      return PassportAiRecommendation(
        headline: 'AI Coach — current focus',
        detail: detail,
        actionLabel: 'View AI Coach feedback',
        destination: PassportHubDestination.aiCoach,
        suggestedEvent: event,
        priorities: priorities,
      );
    }

    if (unanalyzed.isNotEmpty) {
      final video = unanalyzed.first;
      return PassportAiRecommendation(
        headline: 'Recommended next AI analysis',
        detail:
            'Run Elite coaching analysis on "${video.displayTitle}" in Video Lab. '
            'SwimIQ builds practice priorities automatically from the race video.',
        actionLabel: 'Analyze in Video Lab',
        destination: PassportHubDestination.videoLab,
        suggestedEvent: video.eventLabel,
        priorities:
            snapshot.nextFocus.isNotEmpty ? [snapshot.nextFocus] : const [],
      );
    }

    if (videos.isNotEmpty) {
      final video = videos.first;
      return PassportAiRecommendation(
        headline: 'Ready for AI Coach review',
        detail:
            '${video.displayTitle} is uploaded. Run Elite analysis in Video Lab '
            'to build your coaching report and top practice priorities.',
        actionLabel: 'Run analysis in Video Lab',
        destination: PassportHubDestination.videoLab,
        suggestedEvent: video.eventLabel,
      );
    }

    final focus = snapshot.currentFocus;
    return PassportAiRecommendation(
      headline: 'Start your AI Coach profile',
      detail:
          'Upload a $focus race video in Video Lab, then run Elite analysis. '
          'SwimIQ reads the swim and builds your coaching report automatically.',
      actionLabel: 'Go to Video Lab',
      destination: PassportHubDestination.videoLab,
      suggestedEvent: focus,
    );
  }

  static List<SwimVideo> _unanalyzedVideos(
    List<SwimVideo> videos,
    List<SwimVideoAnalysis> analyses,
  ) {
    final analyzedIds =
        analyses.map((analysis) => analysis.swimVideoId).whereType<String>().toSet();
    return videos
        .where((video) => video.id != null && !analyzedIds.contains(video.id))
        .toList();
  }

  static SwimVideoAnalysis? _latestAnalysis(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return null;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }
}
