import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/goal.dart';
import '../datasources/supabase_datasource.dart';
import '../services/supabase_service.dart';
import '../../providers/swimmer_providers.dart';

class GoalRepository {
  GoalRepository(this._datasource);

  final SupabaseDatasource _datasource;

  Future<List<Goal>> fetchForSwimmer(String swimmer) async {
    final rows = await _datasource.fetchBySwimmer(
      table: AppConstants.goalsTable,
      swimmer: swimmer,
    );

    return rows.map(Goal.fromJson).toList();
  }

  Future<void> insert(Goal goal) async {
    await _datasource.insert(
      table: AppConstants.goalsTable,
      row: goal.toInsertJson(),
    );
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(
    SupabaseDatasource(ref.watch(supabaseClientProvider)),
  );
});

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  ref.watch(swimmerBootstrapProvider);
  final swimmerKey = ref.watch(activeSwimmerKeyProvider);
  if (swimmerKey == null) return [];

  return ref.read(goalRepositoryProvider).fetchForSwimmer(swimmerKey);
});
