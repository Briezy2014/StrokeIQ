import 'swim_time_utils.dart';

/// A single race log entry used for personal-best calculations.
class RaceLogEntry {
  const RaceLogEntry({
    required this.stroke,
    required this.distance,
    required this.course,
    required this.timeSeconds,
    required this.date,
  });

  final String stroke;
  final int distance;
  final String course;
  final double timeSeconds;
  final DateTime? date;
}

/// Personal-best helpers — ported from the Streamlit application.
class PersonalBestUtils {
  PersonalBestUtils._();

  static List<RaceLogEntry> bestByEvent(List<RaceLogEntry> logs) {
    if (logs.isEmpty) return [];

    final grouped = <String, RaceLogEntry>{};
    for (final log in logs) {
      final key = '${log.stroke}|${log.distance}|${log.course}';
      final existing = grouped[key];
      if (existing == null || log.timeSeconds < existing.timeSeconds) {
        grouped[key] = log;
      }
    }

    final results = grouped.values.toList()
      ..sort((a, b) {
        final strokeCompare = a.stroke.compareTo(b.stroke);
        if (strokeCompare != 0) return strokeCompare;
        return a.distance.compareTo(b.distance);
      });

    return results;
  }

  static bool isNewPersonalBest({
    required List<RaceLogEntry> previousLogs,
    required String stroke,
    required int distance,
    required String course,
    required double timeSeconds,
  }) {
    final matching = previousLogs.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == course,
    );

    if (matching.isEmpty) return true;

    final previousBest = matching
        .map((log) => log.timeSeconds)
        .reduce((a, b) => a < b ? a : b);

    return timeSeconds < previousBest;
  }

  static String formatBestTime(double seconds) {
    return SwimTimeUtils.secondsToSwimTime(seconds);
  }
}
