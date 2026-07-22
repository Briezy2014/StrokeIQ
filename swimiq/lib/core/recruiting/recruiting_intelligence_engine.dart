import '../../data/models/personal_best_entry.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/college_recruiting_benchmark_catalog.dart';
import '../services/usa_motivational_standards_catalog.dart';
import '../utils/next_cut_progress.dart';
import '../utils/swim_time.dart';
import '../utils/swimiq_standards_profile.dart';

/// Recruiting intelligence with benchmark-matched named schools + optional Gemini summary.
class RecruitingIntelligenceReport {
  const RecruitingIntelligenceReport({
    required this.recruitingLevel,
    required this.strengths,
    required this.focusAreas,
    required this.milestones,
    required this.divisionFit,
    required this.reachSchools,
    required this.targetSchools,
    required this.likelySchools,
    required this.genericReachSchools,
    required this.genericTargetSchools,
    required this.genericLikelySchools,
    required this.timeProjections,
    required this.eventRecommendations,
    required this.improvementCurve,
    this.schoolMatches = const [],
    this.geminiCoachSummary,
    this.benchmarkDisclaimer = '',
    this.usedNamedSchoolMatching = false,
  });

  final String recruitingLevel;
  final List<String> strengths;
  final List<String> focusAreas;
  final List<String> milestones;
  final List<String> divisionFit;
  final List<String> reachSchools;
  final List<String> targetSchools;
  final List<String> likelySchools;
  final List<String> genericReachSchools;
  final List<String> genericTargetSchools;
  final List<String> genericLikelySchools;
  final List<TimeProjection> timeProjections;
  final List<String> eventRecommendations;
  final List<String> improvementCurve;
  final List<CollegeSchoolMatch> schoolMatches;
  final String? geminiCoachSummary;
  final String benchmarkDisclaimer;
  final bool usedNamedSchoolMatching;
}

class TimeProjection {
  const TimeProjection({
    required this.eventLabel,
    required this.currentTime,
    required this.projectedTime,
    required this.targetSchoolTime,
    required this.gapSeconds,
    this.targetSchoolName,
  });

  final String eventLabel;
  final String currentTime;
  final String projectedTime;
  final String targetSchoolTime;
  final double gapSeconds;
  final String? targetSchoolName;
}

class RecruitingIntelligenceEngine {
  RecruitingIntelligenceEngine._();

  static RecruitingIntelligenceReport build({
    required SwimmerProfile? profile,
    required List<PersonalBestEntry> personalBests,
    required int swimIqScore,
    required int meetCount,
    required int videoCount,
    required bool passportComplete,
    CollegeRecruitingBenchmarkCatalog? benchmarkCatalog,
    UsaMotivationalStandardsCatalog? standardsCatalog,
    String? geminiCoachSummary,
  }) {
    final topPb = personalBests.isNotEmpty ? personalBests.first : null;
    final favorite = profile?.favoriteEvent?.trim();
    final primaryStroke = profile?.primaryStroke ?? 'Freestyle';

    final level = _recruitingLevel(swimIqScore, personalBests.length, meetCount);
    final divisionFit = _divisionFit(swimIqScore, personalBests.length);

    final schoolMatches = benchmarkCatalog?.matchSchools(
          personalBests: personalBests,
          profile: profile,
        ) ??
        const <CollegeSchoolMatch>[];
    final usedNamed = schoolMatches.isNotEmpty;

    return RecruitingIntelligenceReport(
      recruitingLevel: level,
      strengths: _strengths(
        profile: profile,
        personalBests: personalBests,
        swimIqScore: swimIqScore,
      ),
      focusAreas: _focusAreas(
        profile: profile,
        meetCount: meetCount,
        videoCount: videoCount,
        passportComplete: passportComplete,
      ),
      milestones: _milestones(
        profile: profile,
        personalBests: personalBests,
        topPb: topPb,
        passportComplete: passportComplete,
        videoCount: videoCount,
        standardsCatalog: standardsCatalog,
      ),
      divisionFit: divisionFit,
      reachSchools: usedNamed
          ? _tierLines(benchmarkCatalog!, schoolMatches, CollegeMatchTier.reach)
          : _schoolBucket(divisionFit, 'reach').map((s) => '  ◦ $s').toList(),
      targetSchools: usedNamed
          ? _tierLines(benchmarkCatalog!, schoolMatches, CollegeMatchTier.target)
          : _schoolBucket(divisionFit, 'target').map((s) => '  ◦ $s').toList(),
      likelySchools: usedNamed
          ? _tierLines(benchmarkCatalog!, schoolMatches, CollegeMatchTier.likely)
          : _schoolBucket(divisionFit, 'likely').map((s) => '  ◦ $s').toList(),
      genericReachSchools:
          _schoolBucket(divisionFit, 'reach').map((s) => '  ◦ $s').toList(),
      genericTargetSchools:
          _schoolBucket(divisionFit, 'target').map((s) => '  ◦ $s').toList(),
      genericLikelySchools:
          _schoolBucket(divisionFit, 'likely').map((s) => '  ◦ $s').toList(),
      timeProjections: _timeProjections(topPb, favorite, schoolMatches),
      eventRecommendations: _eventRecommendations(
        personalBests: personalBests,
        favorite: favorite,
        primaryStroke: primaryStroke,
      ),
      improvementCurve: _improvementCurve(swimIqScore, meetCount),
      schoolMatches: schoolMatches,
      geminiCoachSummary: geminiCoachSummary,
      benchmarkDisclaimer: benchmarkCatalog?.disclaimer ?? '',
      usedNamedSchoolMatching: usedNamed,
    );
  }

  static String _recruitingLevel(
    int swimIqScore,
    int pbCount,
    int meetCount,
  ) {
    if (swimIqScore >= 800 && pbCount >= 6 && meetCount >= 8) {
      return 'National Division I Prospect';
    }
    if (swimIqScore >= 650 && pbCount >= 4) {
      return 'Regional Division I Prospect';
    }
    if (swimIqScore >= 500) return 'Developing College Prospect';
    return 'Early Recruiting Journey';
  }

  static List<String> _divisionFit(int swimIqScore, int pbCount) {
    final fits = <String>[];
    if (swimIqScore >= 750 && pbCount >= 5) {
      fits.add('NCAA Division I — competitive range (projection)');
    } else if (swimIqScore >= 600) {
      fits.add('Mid-Major Division I — competitive range (projection)');
    }
    if (swimIqScore >= 450) {
      fits.add('Division II — competitive range (projection)');
    }
    fits.add('Division III — academic + athletic fit (projection)');
    if (swimIqScore < 700) {
      fits.add('NAIA — strong opportunity (projection)');
    }
    return fits;
  }

  static List<String> _schoolBucket(List<String> divisionFit, String bucket) {
    if (divisionFit.isEmpty) {
      return ['Add meet results to unlock school matching'];
    }
    switch (bucket) {
      case 'reach':
        return [
          'Power conference D1 programs (projection — not a guarantee)',
          'Top-ranked Central U.S. programs in your stroke specialty',
        ];
      case 'target':
        return [
          'Mid-major D1 programs aligned with your times',
          'Strong academic D3 programs with competitive swimming',
        ];
      case 'likely':
        return [
          'D2 programs where your times are within recruiting range',
          'NAIA programs with active recruiting in your region',
        ];
      default:
        return [];
    }
  }

  static List<String> _strengths({
    required SwimmerProfile? profile,
    required List<PersonalBestEntry> personalBests,
    required int swimIqScore,
  }) {
    final items = <String>[];
    if (profile?.primaryStroke != null) {
      items.add('Strong ${profile!.primaryStroke!.toLowerCase()} focus');
    }
    if (personalBests.length >= 4) {
      items.add('Multi-event depth (${personalBests.length} official PBs)');
    }
    if (swimIqScore >= 600) {
      items.add('Consistent improvement trend in SwimIQ score');
    }
    if (profile?.gpa != null) {
      items.add('Academic profile supports recruiting (${profile!.gpa} GPA)');
    }
    if (items.isEmpty) {
      items.add('Building foundation — log meets to unlock strengths');
    }
    return items;
  }

  static List<String> _focusAreas({
    required SwimmerProfile? profile,
    required int meetCount,
    required int videoCount,
    required bool passportComplete,
  }) {
    final items = <String>[];
    if (meetCount < 4) {
      items.add('Increase race frequency in championship-season meets');
    }
    if (videoCount < 2) {
      items.add('Upload race videos for coach review');
    }
    if (!passportComplete) {
      items.add('Complete Athlete Passport recruiting fields');
    }
    if (profile?.favoriteEvent == null) {
      items.add('Define a primary recruiting event');
    } else {
      items.add('Build race readiness around ${profile!.favoriteEvent}');
    }
    return items;
  }

  /// Next milestones prioritize the next USA letter cut (AA / AAA / AAAA),
  /// not generic “regionals” that most club swimmers can already enter.
  static List<String> _milestones({
    required SwimmerProfile? profile,
    required List<PersonalBestEntry> personalBests,
    required PersonalBestEntry? topPb,
    required bool passportComplete,
    required int videoCount,
    UsaMotivationalStandardsCatalog? standardsCatalog,
  }) {
    final items = <String>[];

    if (standardsCatalog != null &&
        SwimIqStandardsProfile.isReady(profile) &&
        personalBests.isNotEmpty) {
      final cutLines = <String>[];
      for (final pb in personalBests.take(4)) {
        final progress = NextCutAnalytics.forSwim(
          catalog: standardsCatalog,
          profile: profile,
          stroke: pb.stroke,
          distance: pb.distance,
          course: pb.course,
          timeSeconds: pb.timeSeconds,
        );
        if (progress == null) continue;
        if (progress.atTopCut) {
          cutLines.add(
            'Hold AAAA standard in ${pb.displayTitle} ${pb.course} — '
            'keep racing championship meets for depth',
          );
          continue;
        }
        if (!progress.hasNextCut) continue;
        final gap = progress.gapSeconds ?? 0;
        final gapText = gap <= 0
            ? 'Cut met'
            : 'drop ${SwimTime.fromSeconds(gap)}';
        cutLines.add(
          'Earn ${progress.nextCut} in ${pb.displayTitle} ${pb.course} '
          '(now ${progress.currentCutLabel}) — $gapText '
          'to ${SwimTime.fromSeconds(progress.nextCutTimeSeconds!)}',
        );
      }
      items.addAll(cutLines.take(3));
    }

    if (items.isEmpty && topPb != null) {
      final target =
          (topPb.timeSeconds * 0.985).clamp(0.01, topPb.timeSeconds);
      items.add(
        'Break ${SwimTime.fromSeconds(target)} in ${topPb.displayTitle} '
        '(~1.5% drop) — add birthday & gender in Passport for AA/AAA cut goals',
      );
    }

    if (videoCount < 2) items.add('Upload two race videos for the highlight reel');
    if (!passportComplete) items.add('Complete Athlete Passport');
    if (profile?.satScore == null && profile?.actScore == null) {
      items.add('Add SAT/ACT scores when available (families & coaches both use these)');
    }
    if (profile?.coachEmail == null || profile!.coachEmail!.trim().isEmpty) {
      items.add('Add your club coach’s email in Passport (separate from athlete email)');
    }
    return items;
  }

  static List<TimeProjection> _timeProjections(
    PersonalBestEntry? topPb,
    String? favorite,
    List<CollegeSchoolMatch> schoolMatches,
  ) {
    if (topPb == null) return [];

    final eventLabel = favorite ?? topPb.displayTitle;
    final current = topPb.timeSeconds;
    final projected = current * 0.975;

    final schoolTarget = () {
      CollegeSchoolMatch? bestTarget;
      for (final match in schoolMatches) {
        if (!match.eventLabel.startsWith(topPb.displayTitle)) continue;
        if (match.tier == CollegeMatchTier.target) {
          bestTarget = match;
          break;
        }
        bestTarget ??= match;
      }
      return bestTarget;
    }();

    final targetSeconds = schoolTarget?.targetSeconds ?? current * 0.96;
    final gap = projected - targetSeconds;

    return [
      TimeProjection(
        eventLabel: eventLabel,
        currentTime: SwimTime.fromSeconds(current),
        projectedTime: SwimTime.fromSeconds(projected),
        targetSchoolTime: SwimTime.fromSeconds(targetSeconds),
        gapSeconds: gap.abs(),
        targetSchoolName: schoolTarget?.school,
      ),
    ];
  }

  static List<String> _tierLines(
    CollegeRecruitingBenchmarkCatalog catalog,
    List<CollegeSchoolMatch> matches,
    CollegeMatchTier tier,
  ) {
    final lines = catalog.linesForTier(matches, tier);
    if (lines.isNotEmpty) return lines;
    return [
      '  ◦ No named match in this tier yet — add official times or College Interests in passport',
    ];
  }

  static List<String> _eventRecommendations({
    required List<PersonalBestEntry> personalBests,
    required String? favorite,
    required String primaryStroke,
  }) {
    if (personalBests.length < 2) {
      return [
        'Log more meet results — SwimIQ will compare event recruiting potential',
      ];
    }

    final sorted = [...personalBests]..sort((a, b) {
        final aScore = _eventScore(a);
        final bScore = _eventScore(b);
        return bScore.compareTo(aScore);
      });

    final best = sorted.first;
    final favoritePb = personalBests.cast<PersonalBestEntry?>().firstWhere(
          (pb) =>
              favorite != null &&
              pb!.displayTitle.toLowerCase().contains(favorite.toLowerCase()),
          orElse: () => null,
        );

    final lines = <String>[
      'You currently score higher nationally in ${best.displayTitle} '
      'than other logged events.',
    ];

    if (favoritePb != null && favoritePb.eventKey != best.eventKey) {
      lines.add(
        'Consider highlighting ${best.displayTitle} — it may maximize '
        'recruiting opportunities over $favorite.',
      );
    } else if (primaryStroke.toLowerCase().contains('fly')) {
      lines.add(
        'Distance fly events (200 Fly, 500 Free) often unlock more '
        'recruiting options than sprint fly alone.',
      );
    }

    return lines;
  }

  static double _eventScore(PersonalBestEntry pb) {
    // Lower time + longer distance = higher recruiting versatility score.
    return pb.distance / pb.timeSeconds;
  }

  static List<String> _improvementCurve(int swimIqScore, int meetCount) {
    return [
      '1-year progression: ${swimIqScore >= 600 ? 'Positive trend' : 'Building baseline'}',
      '2-year progression: Log more seasons to unlock full curve',
      'Seasonal drops: Track championship meets for taper improvements',
      'Meet consistency: $meetCount meets logged — coaches value steady attendance',
    ];
  }
}
