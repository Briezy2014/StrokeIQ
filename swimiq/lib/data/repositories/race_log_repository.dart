import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/race_log.dart';
import '../datasources/supabase_datasource.dart';
import '../services/supabase_service.dart';
import '../../providers/swimmer_providers.dart';

class RaceLogRepository {
  RaceLogRepository(this._datasource);

  final SupabaseDatasource _datasource;

  Future<List<RaceLog>> fetchForSwimmer(String swimmer) async {
    final rows = await _datasource.fetchBySwimmer(
      table: AppConstants.raceLogsTable,
      swimmer: swimmer,
    );

    final logs = rows.map(RaceLog.fromJson).toList()
      ..sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return logs;
  }

  Future<void> insert(RaceLog log) async {
    await _datasource.insert(
      table: AppConstants.raceLogsTable,
      row: log.toInsertJson(),
    );
  }
}

final raceLogRepositoryProvider = Provider<RaceLogRepository>((ref) {
  return RaceLogRepository(
    SupabaseDatasource(ref.watch(supabaseClientProvider)),
  );
});

final raceLogsProvider = FutureProvider<List<RaceLog>>((ref) async {
  final swimmerKey = ref.watch(activeSwimmerKeyProvider);
  if (swimmerKey == null) return [];

  return ref.read(raceLogRepositoryProvider).fetchForSwimmer(swimmerKey);
});
