import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';

class VideoCompareSide {
  const VideoCompareSide({
    required this.title,
    required this.event,
    required this.overallScore,
    required this.techniqueScore,
    required this.paceScore,
    required this.priorities,
    required this.strengths,
    required this.improvements,
    required this.engine,
    this.analyzedAt,
  });

  final String title;
  final String event;
  final int overallScore;
  final int techniqueScore;
  final int paceScore;
  final List<String> priorities;
  final List<String> strengths;
  final List<String> improvements;
  final String? engine;
  final DateTime? analyzedAt;
}

class VideoCompareBrief {
  const VideoCompareBrief({
    required this.headline,
    required this.summary,
    required this.newer,
    required this.older,
    required this.scoreDelta,
    required this.insights,
  });

  final String headline;
  final String summary;
  final VideoCompareSide? newer;
  final VideoCompareSide? older;
  final int? scoreDelta;
  final List<String> insights;
}

/// Side-by-side comparison of the two most recent Video Lab analyses.
abstract final class VideoCompareService {
  static VideoCompareBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final analyses = _sortedAnalyses(data.userFacingVideoAnalyses);
    if (analyses.length < 2) {
      return VideoCompareBrief(
        headline: 'Video compare',
        summary: analyses.isEmpty
            ? 'Upload and analyze at least two videos in Video Lab to compare progress.'
            : 'One analysis on file — run Video Lab on a second swim to unlock compare.',
        newer: analyses.isNotEmpty
            ? _sideFromAnalysis(analyses.first, data.userFacingVideos)
            : null,
        older: null,
        scoreDelta: null,
        insights: const [
          'Film the same event from a similar angle for the clearest comparison.',
        ],
      );
    }

    final newer = analyses[0];
    final older = analyses[1];
    final newerSide = _sideFromAnalysis(newer, data.userFacingVideos);
    final olderSide = _sideFromAnalysis(older, data.userFacingVideos);
    final delta = newer.overallScore - older.overallScore;

    final insights = <String>[
      if (delta > 0)
        'Overall score improved by $delta points.'
      else if (delta < 0)
        'Overall score dropped by ${delta.abs()} points — review newer priorities.'
      else
        'Overall score unchanged — check technique vs pace breakdown.',
      if (newer.techniqueScore != older.techniqueScore)
        'Technique: ${older.techniqueScore} → ${newer.techniqueScore}.',
      if (newer.paceScore != older.paceScore)
        'Pace: ${older.paceScore} → ${newer.paceScore}.',
    ];

    return VideoCompareBrief(
      headline: 'Video compare',
      summary:
          'Side-by-side look at your two latest Video Lab runs — scores, '
          'priorities, and what changed.',
      newer: newerSide,
      older: olderSide,
      scoreDelta: delta,
      insights: insights,
    );
  }

  static List<SwimVideoAnalysis> _sortedAnalyses(
    List<SwimVideoAnalysis> analyses,
  ) {
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted;
  }

  static VideoCompareSide _sideFromAnalysis(
    SwimVideoAnalysis analysis,
    List<SwimVideo> videos,
  ) {
    SwimVideo? video;
    final videoId = analysis.swimVideoId;
    if (videoId != null) {
      for (final item in videos) {
        if (item.id == videoId) {
          video = item;
          break;
        }
      }
    }

    return VideoCompareSide(
      title: video?.displayTitle ?? 'Swim video',
      event: analysis.analysisJson?['event']?.toString() ??
          video?.eventLabel ??
          'Event unknown',
      overallScore: analysis.overallScore,
      techniqueScore: analysis.techniqueScore,
      paceScore: analysis.paceScore,
      priorities: analysis.topPriorities,
      strengths: _lines(analysis.strengths),
      improvements: _lines(analysis.improvements),
      engine: analysis.analysisEngine,
      analyzedAt: analysis.createdAt,
    );
  }

  static List<String> _lines(String text) {
    return text
        .split(RegExp(r'[\n•]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
