import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/models/personal_best_entry.dart';
import '../../data/models/swimmer_profile.dart';
import '../utils/swim_stroke_utils.dart';
import '../utils/swim_time.dart';
import '../utils/swimiq_gender.dart';

enum CollegeMatchTier { reach, target, likely }

/// One benchmarked college program matched to a swimmer PB.
class CollegeSchoolMatch {
  const CollegeSchoolMatch({
    required this.school,
    required this.division,
    required this.conference,
    required this.region,
    required this.eventLabel,
    required this.swimmerTimeSeconds,
    required this.reachSeconds,
    required this.targetSeconds,
    required this.likelySeconds,
    required this.tier,
    required this.gapToTargetSeconds,
    this.interestBoost = 0,
  });

  final String school;
  final String division;
  final String conference;
  final String region;
  final String eventLabel;
  final double swimmerTimeSeconds;
  final double reachSeconds;
  final double targetSeconds;
  final double likelySeconds;
  final CollegeMatchTier tier;
  final double gapToTargetSeconds;
  final int interestBoost;

  String get tierLabel => switch (tier) {
        CollegeMatchTier.reach => 'Reach',
        CollegeMatchTier.target => 'Target',
        CollegeMatchTier.likely => 'Likely',
      };

  String get summaryLine {
    final gap = gapToTargetSeconds;
    final gapText = gap <= 0
        ? '${SwimTime.fromSeconds(gap.abs())} under target'
        : '${SwimTime.fromSeconds(gap)} to target';
    return '$school ($division · $conference · $region) — $eventLabel: '
        'your ${SwimTime.fromSeconds(swimmerTimeSeconds)}, '
        'recruit ~${SwimTime.fromSeconds(reachSeconds)}–${SwimTime.fromSeconds(likelySeconds)} '
        '($gapText). Verify on SwimCloud.';
  }
}

class CollegeProgramBenchmark {
  const CollegeProgramBenchmark({
    required this.gender,
    required this.stroke,
    required this.distance,
    required this.course,
    required this.reachSeconds,
    required this.targetSeconds,
    required this.likelySeconds,
  });

  final String gender;
  final String stroke;
  final int distance;
  final String course;
  final double reachSeconds;
  final double targetSeconds;
  final double likelySeconds;
}

class CollegeRecruitingProgram {
  const CollegeRecruitingProgram({
    required this.school,
    required this.division,
    required this.conference,
    required this.region,
    required this.benchmarks,
  });

  final String school;
  final String division;
  final String conference;
  final String region;
  final List<CollegeProgramBenchmark> benchmarks;
}

class CollegeRecruitingBenchmarkCatalog {
  CollegeRecruitingBenchmarkCatalog._({
    required this.versionLabel,
    required this.disclaimer,
    required this.programs,
  });

  static const assetPath = 'assets/data/college_recruiting_benchmarks_seed.json';

  /// Skip “reach” matches that are unrealistically far from the program’s likely band.
  static const maxReachFactor = 1.10;
  static const maxReachGapSeconds = 8.0;

  final String versionLabel;
  final String disclaimer;
  final List<CollegeRecruitingProgram> programs;

  static Future<CollegeRecruitingBenchmarkCatalog> loadFromAssets() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final programs = (decoded['programs'] as List? ?? [])
        .map((item) => _programFromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return CollegeRecruitingBenchmarkCatalog._(
      versionLabel: decoded['version_label']?.toString() ?? '',
      disclaimer: decoded['disclaimer']?.toString() ?? '',
      programs: programs,
    );
  }

  static CollegeRecruitingProgram _programFromJson(Map<String, dynamic> json) {
    final benchmarks = (json['benchmarks'] as List? ?? [])
        .map((item) {
          final row = Map<String, dynamic>.from(item as Map);
          return CollegeProgramBenchmark(
            gender: row['gender']?.toString() ?? 'Women',
            stroke: row['stroke']?.toString() ?? '',
            distance: (row['distance'] as num?)?.toInt() ?? 0,
            course: row['course']?.toString() ?? '',
            reachSeconds: (row['reach_seconds'] as num).toDouble(),
            targetSeconds: (row['target_seconds'] as num).toDouble(),
            likelySeconds: (row['likely_seconds'] as num).toDouble(),
          );
        })
        .toList();

    return CollegeRecruitingProgram(
      school: json['school']?.toString() ?? '',
      division: json['division']?.toString() ?? '',
      conference: json['conference']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      benchmarks: benchmarks,
    );
  }

  List<CollegeSchoolMatch> matchSchools({
    required List<PersonalBestEntry> personalBests,
    required SwimmerProfile? profile,
    int maxPerTier = 5,
  }) {
    final gender = SwimIqGender.standardsGenderOrNull(profile) ?? 'Girls';
    final normalizedGender =
        gender.toLowerCase().startsWith('m') ? 'Men' : 'Women';
    final interestTokens = _interestTokens(profile?.collegeInterests);
    final hardSchoolFilters = interestTokens
        .where((token) => !_isBroadRegionToken(token) && token.length >= 4)
        .toList();

    final matches = <CollegeSchoolMatch>[];
    for (final pb in personalBests) {
      for (final program in programs) {
        final haystack =
            '${program.region} ${program.school} ${program.conference}'
                .toLowerCase();

        // Soft preference: broad regions boost ranking; specific school names
        // hard-filter. Empty interests → consider all U.S. / Central U.S. programs.
        if (hardSchoolFilters.isNotEmpty &&
            !hardSchoolFilters.any(haystack.contains)) {
          // Still allow if only broad tokens were meant — already filtered above.
          // If user typed a specific school that doesn't match, skip.
          final onlyBroad = interestTokens.every(_isBroadRegionToken);
          if (!onlyBroad) continue;
        }

        final boost = _interestBoost(haystack, interestTokens);

        for (final bench in program.benchmarks) {
          if (bench.gender != normalizedGender) continue;
          if (SwimStrokeUtils.canonical(bench.stroke) !=
              SwimStrokeUtils.canonical(pb.stroke)) {
            continue;
          }
          if (bench.distance != pb.distance) continue;
          if (bench.course.toUpperCase() != pb.course.toUpperCase()) continue;

          final tier = _tierForTime(pb.timeSeconds, bench);
          if (tier == null) continue;

          matches.add(
            CollegeSchoolMatch(
              school: program.school,
              division: program.division,
              conference: program.conference,
              region: program.region,
              eventLabel: '${pb.displayTitle} ${pb.course}',
              swimmerTimeSeconds: pb.timeSeconds,
              reachSeconds: bench.reachSeconds,
              targetSeconds: bench.targetSeconds,
              likelySeconds: bench.likelySeconds,
              tier: tier,
              gapToTargetSeconds: pb.timeSeconds - bench.targetSeconds,
              interestBoost: boost,
            ),
          );
        }
      }
    }

    matches.sort((a, b) {
      final boostOrder = b.interestBoost.compareTo(a.interestBoost);
      if (boostOrder != 0) return boostOrder;
      final tierOrder = a.tier.index.compareTo(b.tier.index);
      if (tierOrder != 0) return tierOrder;
      return a.gapToTargetSeconds.abs().compareTo(b.gapToTargetSeconds.abs());
    });

    // Prefer one best event line per school within each tier.
    final reach = <CollegeSchoolMatch>[];
    final target = <CollegeSchoolMatch>[];
    final likely = <CollegeSchoolMatch>[];
    final seenReach = <String>{};
    final seenTarget = <String>{};
    final seenLikely = <String>{};

    for (final match in matches) {
      switch (match.tier) {
        case CollegeMatchTier.reach:
          if (reach.length < maxPerTier && seenReach.add(match.school)) {
            reach.add(match);
          }
        case CollegeMatchTier.target:
          if (target.length < maxPerTier && seenTarget.add(match.school)) {
            target.add(match);
          }
        case CollegeMatchTier.likely:
          if (likely.length < maxPerTier && seenLikely.add(match.school)) {
            likely.add(match);
          }
      }
    }

    return [...reach, ...target, ...likely];
  }

  static List<String> _interestTokens(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .toLowerCase()
        .split(RegExp(r'[,;/|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map(_normalizeInterestToken)
        .toList();
  }

  static String _normalizeInterestToken(String token) {
    final cleaned = token.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.contains('central') ||
        cleaned == 'midwest' ||
        cleaned == 'mid west' ||
        cleaned.contains('united states') ||
        cleaned == 'usa' ||
        cleaned == 'u.s.' ||
        cleaned == 'us') {
      return 'central us';
    }
    // Keep specific school phrases intact before collapsing to state names.
    const schoolHints = [
      'ohio state',
      'michigan',
      'indiana',
      'purdue',
      'wisconsin',
      'minnesota',
      'northwestern',
      'notre dame',
      'louisville',
      'kentucky',
      'missouri',
      'cincinnati',
      'miami',
      'kenyon',
      'denison',
      'grand valley',
      'drury',
      'chicago',
      'carleton',
      'ball state',
    ];
    for (final hint in schoolHints) {
      if (cleaned.contains(hint)) return hint;
    }
    if (cleaned == 'ohio' || cleaned.endsWith(' ohio')) return 'ohio';
    if (cleaned.contains('illinois')) return 'illinois';
    if (cleaned.contains('iowa')) return 'iowa';
    return cleaned;
  }

  static bool _isBroadRegionToken(String token) {
    const broad = {
      'central us',
      'midwest',
      'ohio',
      'indiana',
      'michigan',
      'illinois',
      'wisconsin',
      'minnesota',
      'missouri',
      'iowa',
      'kentucky',
    };
    if (broad.contains(token)) return true;
    return token.contains('big ten') ||
        token == 'mac' ||
        token.contains('ncaa') ||
        token.contains('division');
  }

  static int _interestBoost(String haystack, List<String> tokens) {
    if (tokens.isEmpty) return 0;
    var score = 0;
    for (final token in tokens) {
      if (token == 'central us' &&
          (haystack.contains('central us') ||
              haystack.contains('midwest') ||
              haystack.contains('ohio') ||
              haystack.contains('indiana') ||
              haystack.contains('michigan') ||
              haystack.contains('illinois') ||
              haystack.contains('wisconsin') ||
              haystack.contains('minnesota') ||
              haystack.contains('missouri') ||
              haystack.contains('iowa') ||
              haystack.contains('kentucky') ||
              haystack.contains('big ten') ||
              haystack.contains('mac'))) {
        score += 2;
        continue;
      }
      if (haystack.contains(token)) score += 3;
    }
    return score;
  }

  /// Returns null when the swimmer is too far from the program to list as a reach.
  static CollegeMatchTier? _tierForTime(
    double swimmerTime,
    CollegeProgramBenchmark bench,
  ) {
    final gapPastLikely = swimmerTime - bench.likelySeconds;
    if (gapPastLikely > maxReachGapSeconds &&
        swimmerTime > bench.likelySeconds * maxReachFactor) {
      return null;
    }
    if (swimmerTime > bench.likelySeconds) return CollegeMatchTier.reach;
    if (swimmerTime > bench.targetSeconds) return CollegeMatchTier.target;
    return CollegeMatchTier.likely;
  }

  List<String> linesForTier(
    List<CollegeSchoolMatch> matches,
    CollegeMatchTier tier,
  ) {
    return matches
        .where((match) => match.tier == tier)
        .map((match) => '  ◦ ${match.summaryLine}')
        .toList();
  }
}
