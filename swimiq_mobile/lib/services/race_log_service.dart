import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/race_log.dart';

class RaceLogService {
  RaceLogService(this._client);

  final SupabaseClient _client;

  Future<List<RaceLog>> fetchLogsForSwimmer(String swimmerName) async {
    final response = await _client
        .from(AppConstants.raceLogsTable)
        .select()
        .eq('swimmer', swimmerName)
        .order('date', ascending: false);

    return (response as List<dynamic>)
        .map((row) => RaceLog.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  List<RaceLog> personalBests(List<RaceLog> logs) {
    final bestByEvent = <String, RaceLog>{};

    for (final log in logs) {
      final key = '${log.event}|${log.course}';
      final existing = bestByEvent[key];
      if (existing == null || log.timeSeconds < existing.timeSeconds) {
        bestByEvent[key] = log;
      }
    }

    return bestByEvent.values.toList()
      ..sort((a, b) => a.event.compareTo(b.event));
  }
}
