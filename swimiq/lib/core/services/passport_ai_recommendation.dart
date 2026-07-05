import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';

enum PassportHubDestination { videoLab, usaStandards, comingSoon }

class PassportAiRecommendation {
  const PassportAiRecommendation({
    required this.headline,
    required this.detail,
    required this.actionLabel,
    required this.destination,
    this.suggestedEvent,
    this.priorities = const [],
    this.engineLabel =
        'SwimIQ V1 notes engine today · Claude vision analysis coming soon',
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

    if (unanalyzed.isNotEmpty) {
      final video = unanalyzed.first;
      return PassportAiRecommendation(
        headline: 'Recommended next AI analysis',
        detail:
            'Run coaching analysis on "${video.displayTitle}". '
            'Add race notes on upload so the AI Coach can rank your top 3 practice priorities.',
        actionLabel: 'Analyze in Video Lab',
        destination: PassportHubDestination.videoLab,
        suggestedEvent: video.eventLabel,
        priorities: snapshot.nextFocus.isNotEmpty ? [snapshot.nextFocus] : const [],
      );
    }

    if (analyses.isNotEmpty) {
      final latest = _latestAnalysis(analyses);
      final priorities = latest?.topPriorities ?? const <String>[];
      final event = snapshot.latestAnalysisEvent ?? latest?.analysisJson?['event']?.toString();

      return PassportAiRecommendation(
        headline: 'AI Coach — current focus',
        detail: priorities.isNotEmpty
            ? priorities.take(3).join('\n')
            : snapshot.nextFocus,
        actionLabel: 'Open Video Lab',
        destination: PassportHubDestination.videoLab,
        suggestedEvent: event,
        priorities: priorities,
      );
    }

    if (videos.isNotEmpty) {
      final video = videos.first;
      return PassportAiRecommendation(
        headline: 'Ready for AI Coach review',
        detail:
            '${video.displayTitle} is uploaded. Run SwimIQ analysis to turn your notes into drills and race prep.',
        actionLabel: 'Run analysis in Video Lab',
        destination: PassportHubDestination.videoLab,
        suggestedEvent: video.eventLabel,
      );
    }

    final focus = snapshot.currentFocus;
    return PassportAiRecommendation(
      headline: 'Start your AI Coach profile',
      detail:
          'Upload a $focus video in Video Lab with short race notes '
          '(start, underwater, strokes, breathing, finish). '
          'SwimDNA™ and Claude frame-by-frame vision will plug in here next.',
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
