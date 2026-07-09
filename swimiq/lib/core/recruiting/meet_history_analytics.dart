import 'package:intl/intl.dart';

import '../../data/models/meet_result.dart';
import '../../data/models/personal_best_entry.dart';
import '../utils/swim_time.dart';

class MeetAttendanceSummary {
  const MeetAttendanceSummary({
    required this.totalMeets,
    required this.totalSwims,
    required this.meetNames,
    required this.seasonSummaries,
    required this.progressionLines,
    required this.championshipHighlights,
  });

  final int totalMeets;
  final int totalSwims;
  final List<String> meetNames;
  final List<SeasonMeetSummary> seasonSummaries;
  final List<String> progressionLines;
  final List<String> championshipHighlights;
}

class SeasonMeetSummary {
  const SeasonMeetSummary({
    required this.seasonLabel,
    required this.meetCount,
    required this.swimCount,
    required this.bestSwims,
  });

  final String seasonLabel;
  final int meetCount;
  final int swimCount;
  final List<String> bestSwims;
}

class MeetHistoryAnalytics {
  MeetHistoryAnalytics._();

  static MeetAttendanceSummary build({
    required List<MeetResult> meetResults,
    required List<PersonalBestEntry> personalBests,
  }) {
    if (meetResults.isEmpty) {
      return const MeetAttendanceSummary(
        totalMeets: 0,
        totalSwims: 0,
        meetNames: [],
        seasonSummaries: [],
        progressionLines: [],
        championshipHighlights: [],
      );
    }

    final meetNames = meetResults.map((r) => r.meetName).toSet().toList()
      ..sort();

    final bySeason = <String, List<MeetResult>>{};
    for (final result in meetResults) {
      final season = _seasonLabel(result.meetDate);
      bySeason.putIfAbsent(season, () => []).add(result);
    }

    final seasonSummaries = bySeason.entries.map((entry) {
      final meets = entry.value.map((r) => r.meetName).toSet();
      final bestByEvent = <String, MeetResult>{};
      for (final swim in entry.value) {
        final key = '${swim.event}|${swim.course}';
        final existing = bestByEvent[key];
        if (existing == null || swim.swimTime < existing.swimTime) {
          bestByEvent[key] = swim;
        }
      }
      final bestSwims = bestByEvent.values
          .toList()
        ..sort((a, b) => a.swimTime.compareTo(b.swimTime));
      return SeasonMeetSummary(
        seasonLabel: entry.key,
        meetCount: meets.length,
        swimCount: entry.value.length,
        bestSwims: bestSwims
            .take(4)
            .map(
              (s) =>
                  '${s.event} ${SwimTime.fromSeconds(s.swimTime)} at ${s.meetName}',
            )
            .toList(),
      );
    }).toList()
      ..sort((a, b) => b.seasonLabel.compareTo(a.seasonLabel));

    return MeetAttendanceSummary(
      totalMeets: meetNames.length,
      totalSwims: meetResults.length,
      meetNames: meetNames,
      seasonSummaries: seasonSummaries,
      progressionLines: _progressionLines(meetResults),
      championshipHighlights: _championshipHighlights(
        meetResults: meetResults,
        personalBests: personalBests,
      ),
    );
  }

  static List<String> _progressionLines(List<MeetResult> meetResults) {
    final byEvent = <String, List<MeetResult>>{};
    for (final result in meetResults) {
      final key = '${result.event} (${result.course})';
      byEvent.putIfAbsent(key, () => []).add(result);
    }

    final lines = <String>[];
    for (final entry in byEvent.entries) {
      final swims = [...entry.value]
        ..sort((a, b) => a.meetDate.compareTo(b.meetDate));
      if (swims.length < 2) continue;
      final first = swims.first;
      final latest = swims.last;
      final delta = latest.swimTime - first.swimTime;
      final direction = delta < 0 ? 'faster' : 'slower';
      final gap = SwimTime.fromSeconds(delta.abs());
      lines.add(
        '${entry.key}: ${SwimTime.fromSeconds(first.swimTime)} → '
        '${SwimTime.fromSeconds(latest.swimTime)} ($gap $direction over '
        '${swims.length} swims)',
      );
    }

    lines.sort();
    return lines.take(6).toList();
  }

  static List<String> _championshipHighlights({
    required List<MeetResult> meetResults,
    required List<PersonalBestEntry> personalBests,
  }) {
    final highlights = <String>[];
    final dateFormat = DateFormat.yMMMd();

    final championshipMeets = meetResults.where((r) {
      final name = r.meetName.toLowerCase();
      return name.contains('champ') ||
          name.contains('futures') ||
          name.contains('sectional') ||
          name.contains('junior') ||
          name.contains('state');
    }).toList()
      ..sort((a, b) => b.meetDate.compareTo(a.meetDate));

    for (final swim in championshipMeets.take(5)) {
      highlights.add(
        '${swim.event} ${SwimTime.fromSeconds(swim.swimTime)} — '
        '${swim.meetName} (${dateFormat.format(swim.meetDate)})',
      );
    }

    if (highlights.isEmpty) {
      for (final pb in personalBests.take(3)) {
        highlights.add(
          'Lifetime best ${pb.displayTitle}: ${pb.formattedTime} (${pb.course})',
        );
      }
    }

    return highlights;
  }

  static String _seasonLabel(DateTime date) {
    // USA swimming short-course season spans Sep–Aug.
    final year = date.month >= 9 ? date.year : date.year - 1;
    return '$year–${year + 1} season';
  }
}
