import '../../data/models/personal_best_entry.dart';
import '../../providers/swimmer_data_provider.dart';
import '../services/college_recruiting_benchmark_catalog.dart';
import '../utils/next_cut_progress.dart';
import '../utils/swim_time.dart';

/// One milestone on the Cut-to-College timeline.
class CutToCollegeStep {
  const CutToCollegeStep({
    required this.kind,
    required this.title,
    required this.detail,
    required this.gapSeconds,
    required this.eventLabel,
  });

  /// usa_cut | college_target | college_likely | college_reach
  final String kind;
  final String title;
  final String detail;
  final double gapSeconds;
  final String eventLabel;

  bool get isMet => gapSeconds <= 0;

  String get gapLabel {
    if (isMet) {
      return kind.startsWith('college') ? 'At/under target' : 'Met';
    }
    final prefix = kind.startsWith('college') ? 'to target' : 'to go';
    return '${SwimTime.fromSeconds(gapSeconds)} $prefix';
  }
}

class CutToCollegeTimeline {
  const CutToCollegeTimeline({
    required this.steps,
    required this.summary,
  });

  final List<CutToCollegeStep> steps;
  final String summary;
}

abstract final class CutToCollegeService {
  CutToCollegeService._();

  static CutToCollegeTimeline build({
    required SwimmerData data,
    CollegeRecruitingBenchmarkCatalog? collegeCatalog,
  }) {
    final pbs = data.personalBests;
    final profile = data.profile;
    final steps = <CutToCollegeStep>[];

    // Closest USA next-cut among PBs.
    NextCutProgress? closestUsa;
    PersonalBestEntry? closestPb;
    for (final pb in pbs) {
      final progress = NextCutAnalytics.forSwim(
        catalog: data.motivationalStandards,
        profile: profile,
        stroke: pb.stroke,
        distance: pb.distance,
        course: pb.course,
        timeSeconds: pb.timeSeconds,
      );
      if (progress == null || !progress.hasNextCut) continue;
      final gap = progress.gapSeconds ?? double.infinity;
      if (closestUsa == null || gap < (closestUsa.gapSeconds ?? double.infinity)) {
        closestUsa = progress;
        closestPb = pb;
      }
    }

    if (closestUsa != null && closestPb != null) {
      steps.add(
        CutToCollegeStep(
          kind: 'usa_cut',
          title: '${closestUsa.nextCut} cut',
          detail:
              '${closestPb.displayTitle} ${closestPb.course}: currently '
              '${closestUsa.currentCutLabel}',
          gapSeconds: closestUsa.gapSeconds ?? 0,
          eventLabel: closestPb.displayTitle,
        ),
      );
    }

    if (collegeCatalog != null && pbs.isNotEmpty) {
      final matches = collegeCatalog.matchSchools(
        personalBests: pbs,
        profile: profile,
        maxPerTier: 4,
      );
      CollegeSchoolMatch? bestTarget;
      for (final match in matches) {
        if (match.tier == CollegeMatchTier.target ||
            match.tier == CollegeMatchTier.likely) {
          if (bestTarget == null ||
              match.gapToTargetSeconds.abs() <
                  bestTarget.gapToTargetSeconds.abs()) {
            bestTarget = match;
          }
        }
      }
      bestTarget ??= matches.isEmpty ? null : matches.first;

      if (bestTarget != null) {
        steps.add(
          CutToCollegeStep(
            kind: 'college_target',
            title: '${bestTarget.school} (${bestTarget.tierLabel})',
            detail:
                '${bestTarget.eventLabel}: your '
                '${SwimTime.fromSeconds(bestTarget.swimmerTimeSeconds)} · '
                'recruit window '
                '${SwimTime.fromSeconds(bestTarget.reachSeconds)}–'
                '${SwimTime.fromSeconds(bestTarget.likelySeconds)}',
            gapSeconds: bestTarget.gapToTargetSeconds,
            eventLabel: bestTarget.eventLabel,
          ),
        );
      }
    }

    final summary = steps.isEmpty
        ? 'Add official PBs (and birthday/gender) to build a Cut-to-College timeline.'
        : steps.map((s) => '${s.title}: ${s.gapLabel}').join(' · ');

    return CutToCollegeTimeline(steps: steps, summary: summary);
  }
}
