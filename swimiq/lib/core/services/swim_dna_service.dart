import '../../core/utils/swim_time.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';

/// Stroke fingerprint built from PBs, training mix, and video trends.
class SwimDnaTrait {
  const SwimDnaTrait({
    required this.label,
    required this.detail,
    required this.strength,
  });

  final String label;
  final String detail;
  /// 0–100 relative emphasis for radar-style display.
  final int strength;
}

class SwimDnaBrief {
  const SwimDnaBrief({
    required this.headline,
    required this.summary,
    required this.traits,
    required this.strokeMix,
    required this.raceProfile,
    required this.videoTrend,
  });

  final String headline;
  final String summary;
  final List<SwimDnaTrait> traits;
  final List<String> strokeMix;
  final String raceProfile;
  final String videoTrend;
}

abstract final class SwimDnaService {
  static SwimDnaBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final profile = data.profile;
    final pbs = data.personalBests;
    final logs = data.raceLogs;
    final analyses = data.userFacingVideoAnalyses;

    final strokeCounts = <String, int>{};
    for (final log in logs) {
      strokeCounts[log.stroke] = (strokeCounts[log.stroke] ?? 0) + 1;
    }

    final traits = <SwimDnaTrait>[];
    final primary = profile?.primaryStroke?.trim();
    if (primary != null && primary.isNotEmpty) {
      traits.add(SwimDnaTrait(
        label: 'Primary stroke',
        detail: primary,
        strength: 90,
      ));
    }

    if (strokeCounts.isNotEmpty) {
      final sorted = strokeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      traits.add(SwimDnaTrait(
        label: 'Training volume',
        detail: '${top.key} (${top.value} sessions)',
        strength: _clampPercent(top.value * 12),
      ));
    }

    if (pbs.isNotEmpty) {
      final fastest = [...pbs]..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
      final best = fastest.first;
      traits.add(SwimDnaTrait(
        label: 'Signature event',
        detail: '${best.distance} ${best.stroke} · ${SwimTime.fromSeconds(best.timeSeconds)}',
        strength: 85,
      ));
    }

    final distances = logs.map((log) => log.distance).toList();
    final raceProfile = _raceProfile(distances);
    traits.add(SwimDnaTrait(
      label: 'Race profile',
      detail: raceProfile,
      strength: raceProfile.contains('Sprint') ? 75 : 60,
    ));

    final videoTrend = _videoTrend(analyses);
    if (videoTrend != null) {
      traits.add(SwimDnaTrait(
        label: 'Technique trend',
        detail: videoTrend,
        strength: _techniqueStrength(analyses),
      ));
    }

    final strokeMix = strokeCounts.entries
        .map((e) => '${e.key}: ${e.value}')
        .toList();

    final headline = profile?.displayName != null
        ? '${profile!.displayName}\'s SwimDNA™'
        : 'Your SwimDNA™';

    return SwimDnaBrief(
      headline: headline,
      summary:
          'A stroke fingerprint from your logged sessions, personal bests, and '
          'video analysis scores — not a genetic test.',
      traits: traits.isEmpty
          ? const [
              SwimDnaTrait(
                label: 'Getting started',
                detail: 'Log sessions and upload video to build your fingerprint.',
                strength: 40,
              ),
            ]
          : traits,
      strokeMix: strokeMix.isEmpty
          ? const ['No stroke mix yet — log training sessions.']
          : strokeMix,
      raceProfile: raceProfile,
      videoTrend: videoTrend ?? 'No video analyses yet. Run Video Lab to add technique trends.',
    );
  }

  static String _raceProfile(List<int> distances) {
    if (distances.isEmpty) return 'Balanced — add sessions to classify sprint vs distance.';
    final avg = distances.reduce((a, b) => a + b) / distances.length;
    if (avg <= 100) return 'Sprinter — majority of work at 100y/m and under.';
    if (avg >= 200) return 'Distance-oriented — longer race focus in the log.';
    return 'Middle-distance — balanced sprint and distance work.';
  }

  static String? _videoTrend(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return null;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    final latest = sorted.first;
    final score = latest.overallScore;
    if (sorted.length >= 2) {
      final previous = sorted[1];
      final delta = score - previous.overallScore;
      if (delta > 0) {
        return 'Technique score up $delta pts (${previous.overallScore} → $score).';
      }
      if (delta < 0) {
        return 'Technique score down ${delta.abs()} pts — review Video Lab priorities.';
      }
    }
    return 'Latest Video Lab score: $score/100.';
  }

  static int _techniqueStrength(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return 50;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return _clampPercent(sorted.first.overallScore);
  }

  static int _clampPercent(int value) => value.clamp(20, 100);
}
