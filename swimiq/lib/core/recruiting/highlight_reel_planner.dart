import '../../data/models/swim_video.dart';
import '../../data/models/video_engine_v2/analysis_metric.dart';
import '../../data/models/video_engine_v2/analysis_results.dart';

/// One timed moment for the recruiting highlight reel.
class HighlightReelSegment {
  const HighlightReelSegment({
    required this.videoId,
    required this.storagePath,
    required this.storageBucket,
    required this.label,
    required this.tag,
    this.startMs,
    this.endMs,
  });

  final String videoId;
  final String storagePath;
  final String storageBucket;
  final String label;
  final String tag;
  final int? startMs;
  final int? endMs;

  Map<String, dynamic> toJson() => {
        'storage_bucket': storageBucket,
        'storage_path': storagePath,
        'label': label,
        'tag': tag,
        if (startMs != null) 'start_ms': startMs,
        if (endMs != null) 'end_ms': endMs,
      };
}

/// Maps builder tags → clip windows using Elite analysis when available.
///
/// When timestamps are null, the Elite FFmpeg service applies sales-friendly
/// default fractions of each video's duration.
class HighlightReelPlanner {
  const HighlightReelPlanner._();

  /// Preferred stitch order for a sales-ready recruiting story.
  static const tagPriority = <String, int>{
    'Best start': 10,
    'Underwaters': 20,
    'Best turn': 30,
    'Best finish': 40,
    'Sprint finish': 50,
    'Race': 60,
  };

  static List<HighlightReelSegment> buildSegments({
    required Map<String, Set<String>> tagsByVideoId,
    required List<SwimVideo> videos,
    Map<String, AnalysisResults?> analysisByVideoId = const {},
  }) {
    final byId = <String, SwimVideo>{};
    for (final video in videos) {
      final id = video.id?.trim();
      if (id != null && id.isNotEmpty) byId[id] = video;
      byId.putIfAbsent(_videoKey(video), () => video);
    }

    final segments = <HighlightReelSegment>[];
    for (final entry in tagsByVideoId.entries) {
      if (entry.value.isEmpty) continue;
      final video = byId[entry.key];
      if (video == null) continue;
      if (video.storagePath.trim().isEmpty) continue;
      final analysis = analysisByVideoId[entry.key] ??
          (video.id == null ? null : analysisByVideoId[video.id!]);
      final tags = entry.value.toList()
        ..sort(
          (a, b) => (tagPriority[a] ?? 100).compareTo(tagPriority[b] ?? 100),
        );
      for (final tag in tags) {
        final window = _windowForTag(tag: tag, analysis: analysis);
        segments.add(
          HighlightReelSegment(
            videoId: video.id ?? entry.key,
            storagePath: video.storagePath,
            storageBucket: 'swim-videos',
            label: video.displayTitle,
            tag: tag,
            startMs: window?.$1,
            endMs: window?.$2,
          ),
        );
      }
    }

    segments.sort((a, b) {
      final pa = tagPriority[a.tag] ?? 100;
      final pb = tagPriority[b.tag] ?? 100;
      if (pa != pb) return pa.compareTo(pb);
      return a.label.compareTo(b.label);
    });
    return segments;
  }

  static String _videoKey(SwimVideo video) {
    final id = video.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    return video.displayTitle;
  }

  static (int, int)? _windowForTag({
    required String tag,
    required AnalysisResults? analysis,
  }) {
    if (analysis == null) return null;
    final duration = _durationMs(analysis);
    final key = tag.toLowerCase();

    if (key.contains('underwater')) {
      final phase = _phaseMatching(analysis, const ['underwater', 'uw']);
      if (phase?.startMs != null && phase?.endMs != null) {
        return (phase!.startMs!, phase.endMs!);
      }
    }
    if (key.contains('start')) {
      final phase = _phaseMatching(analysis, const ['underwater', 'uw', 'start']);
      if (phase?.startMs != null) {
        final end = phase!.endMs ?? (phase.startMs! + 3500);
        return (phase.startMs!, end);
      }
      if (duration != null) return (0, (duration * 0.14).round());
    }
    if (key.contains('turn')) {
      final phase = _phaseMatching(analysis, const ['turn']);
      final metric = _metricMatching(analysis, const ['turn', 'wall']);
      final center = phase?.startMs ?? metric?.startMs;
      if (center != null) {
        return ((center - 1800).clamp(0, center), center + 2200);
      }
    }
    if (key.contains('finish')) {
      final phase = _phaseMatching(analysis, const ['finish']);
      final metric = _metricMatching(analysis, const ['finish', 'final_reach']);
      final center = phase?.endMs ?? phase?.startMs ?? metric?.endMs ?? metric?.startMs;
      if (center != null) {
        final start = (center - 3500).clamp(0, center);
        return (start, center + 800);
      }
      if (duration != null) return (((duration * 0.82).round()), duration);
    }
    if (key == 'race' && duration != null) {
      return (0, (duration * 0.22).round().clamp(1500, duration));
    }
    return null;
  }

  static int? _durationMs(AnalysisResults results) {
    final video = results.video;
    if (video != null) {
      for (final key in ['duration_ms', 'durationMs', 'duration']) {
        final raw = video[key];
        if (raw is num && raw > 0) {
          if (key == 'duration' && raw < 1000) return (raw * 1000).round();
          return raw.round();
        }
      }
    }
    var maxEnd = 0;
    for (final phase in results.phases) {
      final end = phase.endMs ?? phase.startMs;
      if (end != null && end > maxEnd) maxEnd = end;
    }
    return maxEnd > 0 ? maxEnd : null;
  }

  static AnalysisPhase? _phaseMatching(
    AnalysisResults results,
    List<String> needles,
  ) {
    for (final phase in results.phases) {
      final name = phase.name.toLowerCase();
      for (final needle in needles) {
        if (name.contains(needle)) return phase;
      }
    }
    return null;
  }

  static AnalysisMetric? _metricMatching(
    AnalysisResults results,
    List<String> needles,
  ) {
    for (final metric in results.metrics) {
      final name = metric.name.toLowerCase();
      for (final needle in needles) {
        if (name.contains(needle)) return metric;
      }
    }
    return null;
  }
}
