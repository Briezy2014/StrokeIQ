import 'package:supabase_flutter/supabase_flutter.dart';

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
}
