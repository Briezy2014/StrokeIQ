import '../models/race_log.dart';
import 'swim_time.dart';

class PersonalBest {
  PersonalBest({
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
  final String date;

  String get formattedTime => SwimTime.fromSeconds(timeSeconds);
}

class PersonalBests {
  static List<PersonalBest> fromRaceLogs(List<RaceLog> logs) {
    final grouped = <String, RaceLog>{};

    for (final log in logs) {
      final key = '${log.stroke}|${log.distance}|${log.course}';
      final existing = grouped[key];
      if (existing == null || log.timeSeconds < existing.timeSeconds) {
        grouped[key] = log;
      }
    }

    final results = grouped.values
        .map(
          (log) => PersonalBest(
            stroke: log.stroke,
            distance: log.distance,
            course: log.course,
            timeSeconds: log.timeSeconds,
            date: log.date,
          ),
        )
        .toList();

    results.sort((a, b) => a.stroke.compareTo(b.stroke));
    return results;
  }

  static bool isNewPersonalBest({
    required List<RaceLog> previousLogs,
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
}
