import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';

enum PassportHubDestination {
  aiCoach,
  videoLab,
  raceIntelligence,
  usaStandards,
  comingSoon,
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
        'AI Coach = what to fix · Video Lab = full critique · Race Intelligence = meet plan',
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
        headline: 'Video ready for full critique',
        detail:
            '"${video.displayTitle}" needs a Video Lab run first. Gemini + '
            'MediaPipe will critique every phase; then AI Coach summarizes what '
            'to fix in practice.',
        actionLabel: 'Run full analysis in Video Lab',
        destination: PassportHubDestination.videoLab,
        suggestedEvent: video.eventLabel,
        priorities: snapshot.nextFocus.isNotEmpty ? [snapshot.nextFocus] : const [],
        engineLabel:
            'Step 1: Video Lab (full breakdown) → Step 2: AI Coach (corrections)',
      );
    }

    if (analyses.isNotEmpty) {
      final latest = _latestAnalysis(analyses);
      final priorities = latest?.topPriorities ?? const <String>[];
      final event = snapshot.latestAnalysisEvent ?? latest?.analysisJson?['event']?.toString();

      return PassportAiRecommendation(
        headline: 'AI Coach — your top corrections',
        detail: priorities.isNotEmpty
            ? priorities.take(3).join('\n')
            : snapshot.nextFocus,
        actionLabel: 'Open AI Coach',
        destination: PassportHubDestination.aiCoach,
        suggestedEvent: event,
        priorities: priorities,
        engineLabel:
            'Corrections from Video Lab · Race Intelligence handles meet strategy',
      );
    }

    if (videos.isNotEmpty) {
      final video = videos.first;
      return PassportAiRecommendation(
        headline: 'Run Video Lab before AI Coach',
        detail:
            '${video.displayTitle} is uploaded. Video Lab critiques everything; '
            'AI Coach then tells you what to try in practice.',
        actionLabel: 'Open Video Lab',
        destination: PassportHubDestination.videoLab,
        suggestedEvent: video.eventLabel,
      );
    }

    final focus = snapshot.currentFocus;
    return PassportAiRecommendation(
      headline: 'Start with Video Lab',
      detail:
          'Upload a $focus video with race notes. Video Lab runs the full '
          'Gemini + MediaPipe critique; AI Coach and Race Intelligence build '
          'from there.',
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
