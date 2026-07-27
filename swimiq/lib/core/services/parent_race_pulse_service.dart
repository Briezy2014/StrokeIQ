import '../../data/models/race_log.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../providers/swimmer_data_provider.dart';
import '../utils/passport_metrics.dart';

/// Plain-English weekly Parent Race Pulse for email/share.
class ParentRacePulse {
  const ParentRacePulse({
    required this.headline,
    required this.paragraphs,
    required this.shareBody,
    required this.weekLabel,
  });

  final String headline;
  final List<String> paragraphs;
  final String shareBody;
  final String weekLabel;
}

abstract final class ParentRacePulseService {
  ParentRacePulseService._();

  static ParentRacePulse build({
    required SwimmerData data,
    required String swimmer,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final weekStart = clock.subtract(Duration(days: clock.weekday - 1));
    final weekLabel =
        '${_month(weekStart.month)} ${weekStart.day}';
    final snapshot = data.passportSnapshot(swimmer);
    final name = snapshot.displayName;
    final weekLogs = _logsThisWeek(data.raceLogs, weekStart);
    final latest = _latestAnalysis(data.userFacingVideoAnalyses);
    final priorities = latest?.topPriorities.take(2).toList() ?? const <String>[];

    final paragraphs = <String>[
      'This week for $name (week of $weekLabel):',
      'SwimIQ score is ${snapshot.swimIqScore > 0 ? snapshot.swimIqScore : 'still building'} '
          'and readiness is "${snapshot.readiness}".',
      if (weekLogs.isEmpty)
        'No training sessions were logged this week yet. Even one short practice note helps the rope climb.'
      else
        'Logged ${weekLogs.length} training session${weekLogs.length == 1 ? '' : 's'} this week.',
      if (snapshot.nextMeet != PassportMetrics.noUpcomingMeetLabel)
        'Upcoming meet: ${snapshot.nextMeet}.'
      else
        'No upcoming meet is synced yet — add one on Log → Meets.',
      if (snapshot.powerIndex.hasEnoughData)
        'Power Index sits at ${snapshot.powerIndex.score}/100 (${snapshot.powerIndex.label}).'
      else
        'Power Index needs official best times plus birthday and gender.',
      if (priorities.isNotEmpty)
        'Latest video coaching focus: ${priorities.join('; ')}.'
      else if (data.userFacingVideos.isNotEmpty)
        'A race video is uploaded — run Analyze in Video Lab for technique priorities.'
      else
        'No race video yet — a short race clip unlocks technique coaching.',
      if (data.goals.isNotEmpty)
        'Active goal: ${data.goals.first.event}.'
      else
        'No goal event set yet.',
    ];

    final shareBody = paragraphs.join('\n\n');
    return ParentRacePulse(
      headline: 'Parent Race Pulse · $name',
      paragraphs: paragraphs,
      shareBody: '$shareBody\n\n— SwimIQ Parent Race Pulse · swimiqapp.com',
      weekLabel: weekLabel,
    );
  }

  static List<RaceLog> _logsThisWeek(List<RaceLog> logs, DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return logs.where((log) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      return !day.isBefore(start);
    }).toList();
  }

  static SwimVideoAnalysis? _latestAnalysis(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return null;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }

  static String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}
