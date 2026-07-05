import '../models/motivational_standard.dart';
import '../models/standard_level.dart';

/// Result of comparing a swim time against one motivational standard row.
class StandardComparison {
  const StandardComparison({
    required this.standard,
    required this.swimTimeSeconds,
    this.currentLevel,
    this.nextLevel,
    this.timeToNextStandard,
    this.percentProgress,
  });

  final MotivationalStandard standard;
  final double swimTimeSeconds;
  final StandardLevel? currentLevel;
  final StandardLevel? nextLevel;
  final double? timeToNextStandard;
  final double? percentProgress;

  bool get hasAchievedAnyLevel => currentLevel != null;

  String get currentLevelLabel => currentLevel?.label ?? 'Below B';

  String get nextLevelLabel => nextLevel?.label ?? 'AAAA';
}

/// Shared analytics helpers for USA Swimming motivational standards.
///
/// Faster swims have lower times. A swimmer achieves a level when
/// [swimTimeSeconds] is less than or equal to that level's cutoff.
abstract final class StandardsAnalytics {
  static StandardLevel? currentStandard({
    required double swimTimeSeconds,
    required MotivationalStandard standard,
  }) {
    return bestStandardAchieved(
      swimTimeSeconds: swimTimeSeconds,
      standard: standard,
    );
  }

  static StandardLevel? nextStandard({
    required double swimTimeSeconds,
    required MotivationalStandard standard,
  }) {
    final achieved = currentStandard(
      swimTimeSeconds: swimTimeSeconds,
      standard: standard,
    );
    if (achieved == null) {
      return StandardLevel.b;
    }
    return achieved.next;
  }

  static double? timeToNextStandard({
    required double swimTimeSeconds,
    required MotivationalStandard standard,
  }) {
    final next = nextStandard(
      swimTimeSeconds: swimTimeSeconds,
      standard: standard,
    );
    if (next == null) {
      return null;
    }

    final nextCutoff = standard.timeForLevel(next);
    return double.parse(
      (swimTimeSeconds - nextCutoff).toStringAsFixed(2),
    );
  }

  static double? percentProgress({
    required double swimTimeSeconds,
    required MotivationalStandard standard,
  }) {
    final achieved = currentStandard(
      swimTimeSeconds: swimTimeSeconds,
      standard: standard,
    );
    final next = nextStandard(
      swimTimeSeconds: swimTimeSeconds,
      standard: standard,
    );

    if (next == null) {
      return achieved == StandardLevel.aaaa ? 100 : null;
    }

    final nextCutoff = standard.timeForLevel(next);
    final startCutoff = achieved == null
        ? standard.timeForLevel(StandardLevel.b) * 1.08
        : standard.timeForLevel(achieved);

    final span = startCutoff - nextCutoff;
    if (span <= 0) {
      return null;
    }

    final raw = ((startCutoff - swimTimeSeconds) / span) * 100;
    return raw.clamp(0, 100).toDouble();
  }

  static StandardLevel? bestStandardAchieved({
    required double swimTimeSeconds,
    required MotivationalStandard standard,
  }) {
    StandardLevel? best;

    for (final level in StandardLevel.values) {
      if (swimTimeSeconds <= standard.timeForLevel(level)) {
        best = level;
      }
    }

    return best;
  }

  static MotivationalStandard? allStandardsForEvent({
    required List<MotivationalStandard> standards,
    required String event,
    required String ageGroup,
    required String gender,
    required String course,
    String? version,
  }) {
    for (final standard in standards) {
      if (standard.event != event) {
        continue;
      }
      if (standard.ageGroup != ageGroup) {
        continue;
      }
      if (standard.gender.toUpperCase() != gender.toUpperCase()) {
        continue;
      }
      if (standard.course.toUpperCase() != course.toUpperCase()) {
        continue;
      }
      if (version != null && standard.version != version) {
        continue;
      }
      return standard;
    }
    return null;
  }

  static StandardComparison compare({
    required double swimTimeSeconds,
    required MotivationalStandard standard,
  }) {
    final achieved = bestStandardAchieved(
      swimTimeSeconds: swimTimeSeconds,
      standard: standard,
    );
    final next = achieved == null ? StandardLevel.b : achieved.next;

    return StandardComparison(
      standard: standard,
      swimTimeSeconds: swimTimeSeconds,
      currentLevel: achieved,
      nextLevel: next,
      timeToNextStandard: timeToNextStandard(
        swimTimeSeconds: swimTimeSeconds,
        standard: standard,
      ),
      percentProgress: percentProgress(
        swimTimeSeconds: swimTimeSeconds,
        standard: standard,
      ),
    );
  }

  static StandardLevel? highestAcrossComparisons(
    Iterable<StandardComparison> comparisons,
  ) {
    StandardLevel? highest;
    for (final comparison in comparisons) {
      final level = comparison.currentLevel;
      if (level == null) {
        continue;
      }
      if (highest == null || level.rank > highest.rank) {
        highest = level;
      }
    }
    return highest;
  }

  static double goalTimeForLevel({
    required MotivationalStandard standard,
    required StandardLevel level,
  }) {
    return standard.timeForLevel(level);
  }

  static String coachInsight({
    required StandardComparison comparison,
    required String event,
  }) {
    final current = comparison.currentLevelLabel;
    final next = comparison.nextLevel?.label;
    final gap = comparison.timeToNextStandard;

    if (next == null || gap == null) {
      return 'You are currently $current in $event. You have reached the top motivational tier for this event.';
    }

    final gapLabel = gap <= 0
        ? 'You are inside the $next cutoff.'
        : 'You are ${gap.toStringAsFixed(2)} seconds from $next.';

    return 'You are currently $current in $event. $gapLabel '
        'Based on today\'s race, improving your breakout and maintaining '
        'stroke tempo over the final 25 meters is likely to provide the '
        'largest improvement toward $next.';
  }
}
