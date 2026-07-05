import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/meet_result.dart';
import '../datasources/supabase_datasource.dart';
import '../services/supabase_service.dart';
import '../../providers/swimmer_providers.dart';

class MeetResultRepository {
  MeetResultRepository(this._datasource);

  final SupabaseDatasource _datasource;

  Future<List<MeetResult>> fetchForSwimmer(String swimmer) async {
    final rows = await _datasource.fetchBySwimmer(
      table: AppConstants.meetResultsTable,
      swimmer: swimmer,
    );

    final results = rows.map(MeetResult.fromJson).toList()
      ..sort((a, b) {
        final aDate = a.meetDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.meetDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return results;
  }

  Future<void> insert(MeetResult result) async {
    await _datasource.insert(
      table: AppConstants.meetResultsTable,
      row: result.toInsertJson(),
    );
  }
}

final meetResultRepositoryProvider = Provider<MeetResultRepository>((ref) {
  return MeetResultRepository(
    SupabaseDatasource(ref.watch(supabaseClientProvider)),
  );
});

final meetResultsProvider = FutureProvider<List<MeetResult>>((ref) async {
  final swimmerKey = ref.watch(activeSwimmerKeyProvider);
  if (swimmerKey == null) return [];

  return ref.read(meetResultRepositoryProvider).fetchForSwimmer(swimmerKey);
});
