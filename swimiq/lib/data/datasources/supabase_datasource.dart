import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

class SupabaseDatasource {
  SupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchBySwimmer({
    required String table,
    required String swimmer,
    String swimmerColumn = 'swimmer',
  }) async {
    final response = await _client
        .from(table)
        .select()
        .eq(swimmerColumn, swimmer);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insert({
    required String table,
    required Map<String, dynamic> row,
  }) async {
    await _client.from(table).insert(row);
  }

  Future<Map<String, dynamic>?> fetchSwimmerProfile(String swimmerName) async {
    final response = await _client
        .from(AppConstants.swimmersTable)
        .select()
        .eq('swimmer_name', swimmerName)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Future<void> insertSwimmerProfile(Map<String, dynamic> row) async {
    await _client.from(AppConstants.swimmersTable).insert(row);
  }

  Future<void> updateSwimmerProfile({
    required String swimmerName,
    required Map<String, dynamic> row,
  }) async {
    await _client
        .from(AppConstants.swimmersTable)
        .update(row)
        .eq('swimmer_name', swimmerName);
  }
}
