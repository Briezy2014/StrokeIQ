import '../../data/models/usa_motivational_standard.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/usa_motivational_standards_catalog.dart';
import 'motivational_cut.dart';
import 'swimiq_age_group.dart';
import 'swimiq_gender.dart';
import 'swimiq_standards_profile.dart';

/// How close a swim is to the next USA motivational cut above the current one.
class NextCutProgress {
  const NextCutProgress({
    required this.currentCutLabel,
    required this.swimmerTimeSeconds,
    this.nextCut,
    this.nextCutTimeSeconds,
    this.gapSeconds,
    this.progressPercent = 0,
    this.atTopCut = false,
  });

  final String currentCutLabel;
  final double swimmerTimeSeconds;
  final String? nextCut;
  final double? nextCutTimeSeconds;
  /// Seconds to drop to reach [nextCut]; zero or negative means the cut is met.
  final double? gapSeconds;
  final double progressPercent;
  final bool atTopCut;

  bool get hasNextCut =>
      !atTopCut && nextCut != null && nextCutTimeSeconds != null;

  bool get isClose => hasNextCut && (gapSeconds ?? double.infinity) <= 2;

  String get gapLabel {
    if (atTopCut) return 'Top USA cut';
    if (!hasNextCut) return '—';
    final gap = gapSeconds ?? 0;
    if (gap <= 0) return 'Cut met';
    return '${_formatGap(gap)} to $nextCut';
  }

  static String _formatGap(double seconds) {
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(2)}s';
    }
    final minutes = seconds ~/ 60;
    final remainder = seconds - minutes * 60;
    return '${minutes}:${remainder.toStringAsFixed(2).padLeft(5, '0')}';
  }
}

abstract final class NextCutAnalytics {
  NextCutAnalytics._();

  static NextCutProgress? forSwim({
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
    required String stroke,
    required int distance,
    required String course,
    required double timeSeconds,
    String? ageGroup,
    String? gender,
  }) {
    if (!SwimIqStandardsProfile.isReady(profile)) return null;

    final resolvedAgeGroup =
        ageGroup ?? SwimIqAgeGroup.fromProfileOrNull(profile)!;
    final resolvedGender =
        gender ?? SwimIqGender.standardsGenderOrNull(profile)!;

    final event = catalog.eventFor(
      ageGroup: resolvedAgeGroup,
      gender: resolvedGender,
      stroke: stroke,
      distance: distance,
      course: course,
    );
    if (event == null) return null;

    final currentCut = MotivationalCut.forSwim(
      catalog: catalog,
      profile: profile,
      stroke: stroke,
      distance: distance,
      course: course,
      timeSeconds: timeSeconds,
      ageGroup: resolvedAgeGroup,
      gender: resolvedGender,
    );
    final currentLabel = currentCut ?? 'Below B';

    if (currentCut == 'AAAA') {
      return NextCutProgress(
        currentCutLabel: currentLabel,
        swimmerTimeSeconds: timeSeconds,
        atTopCut: true,
        progressPercent: 100,
      );
    }

    final nextCut = currentCut == null
        ? 'B'
        : _nextLevel(currentCut);
    if (nextCut == null) {
      return NextCutProgress(
        currentCutLabel: currentLabel,
        swimmerTimeSeconds: timeSeconds,
        atTopCut: true,
        progressPercent: 100,
      );
    }

    final nextCutTime = event.cuts[nextCut];
    if (nextCutTime == null) return null;

    final gap = timeSeconds - nextCutTime;
    final progress = _progressPercent(
      swimmerTime: timeSeconds,
      currentCut: currentCut,
      nextCutTime: nextCutTime,
      event: event,
    );

    return NextCutProgress(
      currentCutLabel: currentLabel,
      swimmerTimeSeconds: timeSeconds,
      nextCut: nextCut,
      nextCutTimeSeconds: nextCutTime,
      gapSeconds: gap,
      progressPercent: progress,
    );
  }

  static String? _nextLevel(String currentCut) {
    final levels = UsaMotivationalStandardsCatalog.standardLevels;
    final index = levels.indexOf(currentCut);
    if (index < 0 || index >= levels.length - 1) return null;
    return levels[index + 1];
  }

  static double _progressPercent({
    required double swimmerTime,
    required String? currentCut,
    required double nextCutTime,
    required UsaMotivationalEventStandard event,
  }) {
    if (currentCut != null) {
      final floor = event.cuts[currentCut];
      if (floor == null || floor <= nextCutTime) return 0;
      final range = floor - nextCutTime;
      final closed = floor - swimmerTime;
      return ((closed / range) * 100).clamp(0.0, 100.0);
    }

    final bTime = event.cuts['B'];
    if (bTime == null || swimmerTime <= bTime) return 100;
    final over = swimmerTime - bTime;
    final window = bTime * 0.2;
    return ((1 - over / window) * 100).clamp(0.0, 100.0);
  }
}
