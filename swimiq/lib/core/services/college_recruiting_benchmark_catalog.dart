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
    return '$school ($division · $conference) — $eventLabel: '
        'your ${SwimTime.fromSeconds(swimmerTimeSeconds)}, '
        'recruit ~${SwimTime.fromSeconds(reachSeconds)}–${SwimTime.fromSeconds(likelySeconds)} '
        '($gapText)';
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
    int maxPerTier = 4,
  }) {
    final gender = SwimIqGender.standardsGenderOrNull(profile) ?? 'Girls';
    final normalizedGender = gender.toLowerCase().startsWith('m') ? 'Men' : 'Women';
    final interests = profile?.collegeInterests?.toLowerCase() ?? '';

    final matches = <CollegeSchoolMatch>[];
    for (final pb in personalBests) {
      for (final program in programs) {
        if (interests.isNotEmpty) {
          final haystack =
              '${program.region} ${program.school} ${program.conference}'
                  .toLowerCase();
          final parts = interests
              .split(RegExp(r'[,;/]'))
              .map((part) => part.trim().toLowerCase())
              .where((part) => part.isNotEmpty);
          if (!parts.any(haystack.contains)) continue;
        }

        for (final bench in program.benchmarks) {
          if (bench.gender != normalizedGender) continue;
          if (SwimStrokeUtils.canonical(bench.stroke) !=
              SwimStrokeUtils.canonical(pb.stroke)) {
            continue;
          }
          if (bench.distance != pb.distance) continue;
          if (bench.course.toUpperCase() != pb.course.toUpperCase()) continue;

          final tier = _tierForTime(pb.timeSeconds, bench);
          matches.add(
            CollegeSchoolMatch(
              school: program.school,
              division: program.division,
              conference: program.conference,
              region: program.region,
              eventLabel: pb.displayTitle + ' ${pb.course}',
              swimmerTimeSeconds: pb.timeSeconds,
              reachSeconds: bench.reachSeconds,
              targetSeconds: bench.targetSeconds,
              likelySeconds: bench.likelySeconds,
              tier: tier,
              gapToTargetSeconds: pb.timeSeconds - bench.targetSeconds,
            ),
          );
        }
      }
    }

    matches.sort((a, b) {
      final tierOrder = a.tier.index.compareTo(b.tier.index);
      if (tierOrder != 0) return tierOrder;
      return a.gapToTargetSeconds.abs().compareTo(b.gapToTargetSeconds.abs());
    });

    final reach = <CollegeSchoolMatch>[];
    final target = <CollegeSchoolMatch>[];
    final likely = <CollegeSchoolMatch>[];
    for (final match in matches) {
      switch (match.tier) {
        case CollegeMatchTier.reach:
          if (reach.length < maxPerTier) reach.add(match);
        case CollegeMatchTier.target:
          if (target.length < maxPerTier) target.add(match);
        case CollegeMatchTier.likely:
          if (likely.length < maxPerTier) likely.add(match);
      }
    }

    return [...reach, ...target, ...likely];
  }

  static CollegeMatchTier _tierForTime(
    double swimmerTime,
    CollegeProgramBenchmark bench,
  ) {
    if (swimmerTime > bench.likelySeconds) return CollegeMatchTier.reach;
    if (swimmerTime > bench.targetSeconds) return CollegeMatchTier.target;
    return CollegeMatchTier.likely;
  }

  List<String> linesForTier(List<CollegeSchoolMatch> matches, CollegeMatchTier tier) {
    return matches
        .where((match) => match.tier == tier)
        .map((match) => '  ◦ ${match.summaryLine}')
        .toList();
  }
}
