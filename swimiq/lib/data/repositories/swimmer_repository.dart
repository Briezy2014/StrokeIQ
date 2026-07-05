import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/swimmer_profile.dart';
import '../datasources/supabase_datasource.dart';
import '../services/supabase_service.dart';
import '../../providers/swimmer_providers.dart';

class SwimmerRepository {
  SwimmerRepository(this._datasource);

  final SupabaseDatasource _datasource;

  Future<SwimmerProfile?> fetchProfile(String swimmerName) async {
    final row = await _datasource.fetchSwimmerProfile(swimmerName);
    if (row == null) return null;
    return SwimmerProfile.fromJson(row);
  }

  Future<void> ensureProfile({
    required String swimmerKey,
    String? email,
  }) async {
    final existing = await fetchProfile(swimmerKey);
    if (existing != null) return;

    final emailLocal = email?.split('@').first;
    final profile = SwimmerProfile(
      swimmerName: swimmerKey,
      preferredName: emailLocal,
    );

    await _datasource.insertSwimmerProfile(profile.toInsertJson());
  }

  Future<void> saveProfile(SwimmerProfile profile) async {
    final existing = await fetchProfile(profile.swimmerName);
    final row = profile.toInsertJson();

    if (existing == null) {
      await _datasource.insertSwimmerProfile(row);
    } else {
      await _datasource.updateSwimmerProfile(
        swimmerName: profile.swimmerName,
        row: row,
      );
    }
  }
}

final swimmerRepositoryProvider = Provider<SwimmerRepository>((ref) {
  return SwimmerRepository(
    SupabaseDatasource(ref.watch(supabaseClientProvider)),
  );
});

final swimmerProfileProvider = FutureProvider<SwimmerProfile?>((ref) async {
  ref.watch(swimmerBootstrapProvider);
  final swimmerKey = ref.watch(activeSwimmerKeyProvider);
  if (swimmerKey == null) return null;

  return ref.read(swimmerRepositoryProvider).fetchProfile(swimmerKey);
});
