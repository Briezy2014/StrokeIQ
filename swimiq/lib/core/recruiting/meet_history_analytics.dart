import 'package:intl/intl.dart';

import '../../data/models/meet_result.dart';
import '../../data/models/personal_best_entry.dart';
import '../utils/swim_time.dart';

class MeetHistorySummary {
  const MeetHistorySummary({
    required this.realMeetCount,
    required this.totalSwims,
    required this.eventCount,
    required this.seasonSummaries,
    required this.progressionLines,
    required this.highlightSwims,
  });

  /// Distinct real meet names (excludes photo uploads / synthetic sources).
  final int realMeetCount;
  final int totalSwims;
  final int eventCount;
  final List<SeasonHighlightSummary> seasonSummaries;
  final List<String> progressionLines;
  final List<String> highlightSwims;
}

class SeasonHighlightSummary {
  const SeasonHighlightSummary({
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

/// Builds recruiting-facing career highlights from meet results + PBs.
class MeetHistoryAnalytics {
  MeetHistoryAnalytics._();

  static const _syntheticMeetLabels = {
    'uploaded best times',
    'uploaded best time',
    'photo upload',
    'best times upload',
    'manual pb upload',
  };

  static MeetHistorySummary build({
    required List<MeetResult> meetResults,
    required List<PersonalBestEntry> personalBests,
  }) {
    if (meetResults.isEmpty && personalBests.isEmpty) {
      return const MeetHistorySummary(
        realMeetCount: 0,
        totalSwims: 0,
        eventCount: 0,
        seasonSummaries: [],
        progressionLines: [],
        highlightSwims: [],
      );
    }

    final realMeets = meetResults
        .map((r) => r.meetName.trim())
        .where((name) => name.isNotEmpty && !_isSyntheticMeet(name))
        .toSet();

    final events = <String>{
      for (final result in meetResults) '${result.event}|${result.course}',
      for (final pb in personalBests) '${pb.displayTitle}|${pb.course}',
    };

    final bySeason = <String, List<MeetResult>>{};
    for (final result in meetResults) {
      final season = _seasonLabel(result.meetDate);
      bySeason.putIfAbsent(season, () => []).add(result);
    }

    final seasonSummaries = bySeason.entries.map((entry) {
      final seasonMeets = entry.value
          .map((r) => r.meetName.trim())
          .where((name) => name.isNotEmpty && !_isSyntheticMeet(name))
          .toSet();
      final bestByEvent = <String, MeetResult>{};
      for (final swim in entry.value) {
        final key = '${swim.event}|${swim.course}';
        final existing = bestByEvent[key];
        if (existing == null || swim.swimTime < existing.swimTime) {
          bestByEvent[key] = swim;
        }
      }
      final bestSwims = bestByEvent.values.toList()
        ..sort((a, b) => a.swimTime.compareTo(b.swimTime));
      return SeasonHighlightSummary(
        seasonLabel: entry.key,
        meetCount: seasonMeets.length,
        swimCount: entry.value.length,
        bestSwims: bestSwims.take(6).map(_formatBestSwim).toList(),
      );
    }).toList()
      ..sort((a, b) => b.seasonLabel.compareTo(a.seasonLabel));

    return MeetHistorySummary(
      realMeetCount: realMeets.length,
      totalSwims: meetResults.length,
      eventCount: events.length,
      seasonSummaries: seasonSummaries,
      progressionLines: _progressionLines(meetResults),
      highlightSwims: _highlightSwims(
        meetResults: meetResults,
        personalBests: personalBests,
      ),
    );
  }

  static bool isSyntheticMeetName(String meetName) => _isSyntheticMeet(meetName);

  static bool _isSyntheticMeet(String meetName) {
    final lower = meetName.trim().toLowerCase();
    if (_syntheticMeetLabels.contains(lower)) return true;
    return lower.startsWith('uploaded best');
  }

  static String _formatBestSwim(MeetResult swim) {
    final time = SwimTime.fromSeconds(swim.swimTime);
    if (_isSyntheticMeet(swim.meetName)) {
      return '${swim.event} $time (${swim.course})';
    }
    return '${swim.event} $time — ${swim.meetName}';
  }

  static List<String> _progressionLines(List<MeetResult> meetResults) {
    final byEvent = <String, List<MeetResult>>{};
    for (final result in meetResults) {
      final key = '${result.event} (${result.course})';
      byEvent.putIfAbsent(key, () => []).add(result);
    }

    final scored = <({String line, double improvement})>[];
    for (final entry in byEvent.entries) {
      final swims = [...entry.value]
        ..sort((a, b) => a.meetDate.compareTo(b.meetDate));
      if (swims.length < 2) continue;
      final first = swims.first;
      final best = swims.reduce(
        (a, b) => a.swimTime <= b.swimTime ? a : b,
      );
      final delta = best.swimTime - first.swimTime;
      final direction = delta < 0 ? 'faster' : (delta > 0 ? 'slower' : 'even');
      final gap = SwimTime.fromSeconds(delta.abs());
      scored.add(
        (
          line: '${entry.key}: ${SwimTime.fromSeconds(first.swimTime)} → '
              '${SwimTime.fromSeconds(best.swimTime)} '
              '($gap $direction over ${swims.length} swims)',
          improvement: -delta,
        ),
      );
    }

    scored.sort((a, b) => b.improvement.compareTo(a.improvement));
    return scored.take(6).map((item) => item.line).toList();
  }

  static List<String> _highlightSwims({
    required List<MeetResult> meetResults,
    required List<PersonalBestEntry> personalBests,
  }) {
    final highlights = <String>[];
    final dateFormat = DateFormat.yMMMd();

    final championshipMeets = meetResults.where((r) {
      if (_isSyntheticMeet(r.meetName)) return false;
      final name = r.meetName.toLowerCase();
      return name.contains('champ') ||
          name.contains('futures') ||
          name.contains('sectional') ||
          name.contains('junior national') ||
          name.contains('state');
    }).toList()
      ..sort((a, b) => a.swimTime.compareTo(b.swimTime));

    for (final swim in championshipMeets.take(5)) {
      highlights.add(
        '${swim.event} ${SwimTime.fromSeconds(swim.swimTime)} — '
        '${swim.meetName} (${dateFormat.format(swim.meetDate)})',
      );
    }

    if (highlights.isEmpty) {
      final sortedPbs = [...personalBests]
        ..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
      for (final pb in sortedPbs.take(5)) {
        highlights.add(
          '${pb.displayTitle}: ${pb.formattedTime} (${pb.course})',
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
