import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swim_time.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../core/utils/swimiq_gender.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';

class StandardsGapTarget {
  const StandardsGapTarget({
    required this.eventLabel,
    required this.standardLevel,
    required this.cutTimeSeconds,
    required this.currentTimeSeconds,
    required this.gapSeconds,
    required this.progressPercent,
  });

  final String eventLabel;
  final String standardLevel;
  final double cutTimeSeconds;
  final double currentTimeSeconds;
  final double gapSeconds;
  final int progressPercent;

  String get gapLabel => SwimTime.fromSeconds(gapSeconds);
  String get cutLabel => SwimTime.fromSeconds(cutTimeSeconds);
  String get currentLabel => SwimTime.fromSeconds(currentTimeSeconds);
}

class StandardsGapBrief {
  const StandardsGapBrief({
    required this.headline,
    required this.summary,
    required this.closestTarget,
    required this.allGaps,
    required this.highestAchieved,
  });

  final String headline;
  final String summary;
  final StandardsGapTarget? closestTarget;
  final List<StandardsGapTarget> allGaps;
  final String highestAchieved;
}

/// Dashboard radar for how close PBs are to the next USA motivational cut.
abstract final class StandardsGapService {
  static StandardsGapBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final profile = data.profile;
    final snapshot = data.passportSnapshot(swimmer);
    final pbs = data.personalBests;
    final catalog = data.motivationalStandards;

    if (!SwimIqStandardsProfile.isReady(profile)) {
      return StandardsGapBrief(
        headline: 'Standards gap radar',
        summary: SwimIqStandardsProfile.setupMessageShort,
        closestTarget: null,
        allGaps: const [],
        highestAchieved: snapshot.highestCut,
      );
    }

    if (pbs.isEmpty) {
      return StandardsGapBrief(
        headline: 'Standards gap radar',
        summary: 'Log sessions to see how many seconds you are from the next cut.',
        closestTarget: null,
        allGaps: const [],
        highestAchieved: snapshot.highestCut,
      );
    }

    final gaps = _computeGaps(
      personalBests: pbs,
      profile: profile,
      catalog: catalog,
    )..sort((a, b) => a.gapSeconds.compareTo(b.gapSeconds));

    final closest = gaps.isNotEmpty ? gaps.first : null;
    final summary = closest != null
        ? '${closest.gapLabel} from ${closest.standardLevel} in ${closest.eventLabel}.'
        : 'You have achieved cuts on logged PBs — set a higher target event.';

    return StandardsGapBrief(
      headline: 'Standards gap radar',
      summary: summary,
      closestTarget: closest,
      allGaps: gaps.take(5).toList(),
      highestAchieved: snapshot.highestCut,
    );
  }

  static List<StandardsGapTarget> _computeGaps({
    required List<RaceLog> personalBests,
    required SwimmerProfile? profile,
    required UsaMotivationalStandardsCatalog catalog,
  }) {
    final ageGroup = SwimIqAgeGroup.fromProfileOrNull(profile)!;
    final gender = SwimIqGender.standardsGenderOrNull(profile)!;
    final gaps = <StandardsGapTarget>[];

    for (final pb in personalBests) {
      final event = catalog.eventFor(
        ageGroup: ageGroup,
        gender: gender,
        stroke: SwimStrokeUtils.canonical(pb.stroke),
        distance: pb.distance,
        course: pb.course,
      );
      if (event == null) continue;

      for (final entry in event.cuts.entries) {
        final cutTime = entry.value;
        if (pb.timeSeconds <= cutTime) continue;
        final gap = pb.timeSeconds - cutTime;
        final span = pb.timeSeconds - cutTime;
        final progress = span > 0
            ? ((cutTime / pb.timeSeconds) * 100).round().clamp(0, 99)
            : 99;
        gaps.add(StandardsGapTarget(
          eventLabel: event.event,
          standardLevel: entry.key,
          cutTimeSeconds: cutTime,
          currentTimeSeconds: pb.timeSeconds,
          gapSeconds: gap,
          progressPercent: progress,
        ));
      }
    }

    return gaps;
  }
}
