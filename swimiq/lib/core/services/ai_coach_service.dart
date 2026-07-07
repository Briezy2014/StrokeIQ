import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';

/// Action-oriented coaching brief — what to try correcting this week.
class AiCoachBrief {
  const AiCoachBrief({
    required this.headline,
    required this.summary,
    required this.correctionsToTry,
    required this.practiceFocus,
    required this.keepDoing,
    required this.hasVideoAnalysis,
    this.sourceVideoTitle,
    this.sourceEvent,
    this.analysisEngine,
  });

  final String headline;
  final String summary;
  final List<String> correctionsToTry;
  final List<String> practiceFocus;
  final List<String> keepDoing;
  final bool hasVideoAnalysis;
  final String? sourceVideoTitle;
  final String? sourceEvent;
  final String? analysisEngine;
}

abstract final class AiCoachService {
  static AiCoachBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final snapshot = data.passportSnapshot(swimmer);
    final latest = _latestAnalysis(data.userFacingVideoAnalyses);
    SwimVideo? latestVideo;
    final latestVideoId = latest?.swimVideoId;
    if (latestVideoId != null) {
      for (final video in data.userFacingVideos) {
        if (video.id == latestVideoId) {
          latestVideo = video;
          break;
        }
      }
    }

    if (latest != null && !latest.isLegacyRulesEngine) {
      final corrections = latest.topPriorities;
      final practice = _linesFromText(latest.improvements);
      final strengths = _linesFromText(latest.strengths);
      final drills = _drillsFromSections(latest);

      return AiCoachBrief(
        headline: 'What to correct from your latest video',
        summary:
            'AI Coach turns your Video Lab breakdown into a short practice plan. '
            'Focus on these fixes before your next race.',
        correctionsToTry: corrections.isNotEmpty
            ? corrections
            : practice.take(3).toList(),
        practiceFocus: drills.isNotEmpty
            ? drills
            : practice.isNotEmpty
                ? practice
                : [
                    'Film another ${snapshot.currentFocus} rep in Video Lab '
                        'with race notes so priorities stay event-specific.',
                  ],
        keepDoing: strengths.isNotEmpty
            ? strengths
            : ['Keep logging sessions so SwimIQ can track progress.'],
        hasVideoAnalysis: true,
        sourceVideoTitle: latestVideo?.displayTitle,
        sourceEvent: latest.analysisJson?['event']?.toString() ??
            snapshot.latestAnalysisEvent,
        analysisEngine: latest.analysisEngine,
      );
    }

    final unanalyzed = data.userFacingVideos.where(
      (video) => data.analysisForVideo(video.id) == null,
    );
    if (unanalyzed.isNotEmpty) {
      final video = unanalyzed.first;
      return AiCoachBrief(
        headline: 'Upload complete — run Video Lab first',
        summary:
            'AI Coach gives corrective feedback after Video Lab runs the full '
            'Gemini + MediaPipe breakdown. "${video.displayTitle}" is waiting '
            'for analysis.',
        correctionsToTry: const [
          'Open Video Lab and run full video analysis on your upload.',
          'Add race notes (start, breakout, breathing, finish) before analyzing.',
        ],
        practiceFocus: [
          'Current focus: ${snapshot.currentFocus}',
          if (snapshot.nextFocus.isNotEmpty) snapshot.nextFocus,
        ],
        keepDoing: const [
          'You already uploaded video — that is the hardest step.',
        ],
        hasVideoAnalysis: false,
        sourceVideoTitle: video.displayTitle,
        sourceEvent: video.eventLabel,
      );
    }

    return AiCoachBrief(
      headline: 'Start with a video, then coach here',
      summary:
          'AI Coach does not re-watch your video. It summarizes what to fix '
          'after Video Lab critiques every phase with Gemini + MediaPipe.',
      correctionsToTry: [
        if (snapshot.nextFocus.isNotEmpty) snapshot.nextFocus,
        'Upload a ${snapshot.currentFocus} race or practice video in Video Lab.',
      ],
      practiceFocus: [
        'Set a goal in Goals tab for your next meet target.',
        'Log training sessions so Race Intelligence can plan pace strategy.',
      ],
      keepDoing: [
        'Current readiness: ${snapshot.readiness}',
        if (snapshot.highestCut != 'Log sessions to compare against cuts')
          'Highest cut: ${snapshot.highestCut}',
      ],
      hasVideoAnalysis: false,
      sourceEvent: snapshot.currentFocus,
    );
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

  static List<String> _linesFromText(String text) {
    return text
        .split(RegExp(r'[\n•]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static List<String> _drillsFromSections(SwimVideoAnalysis analysis) {
    final drills = <String>[];
    for (final entry in analysis.coachingSections.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('drill') ||
          key.contains('practice') ||
          key.contains('fix')) {
        drills.add('${entry.key}: ${entry.value}'.trim());
      }
    }
    return drills;
  }
}
