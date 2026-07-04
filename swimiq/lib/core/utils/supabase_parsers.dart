String? parseUuid(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String? parseOptionalText(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? parseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String swimmerFromJson(Map<String, dynamic> json) {
  final swimmer = parseOptionalText(json['swimmer']);
  if (swimmer != null) return swimmer;
  return parseOptionalText(json['swimmer_name']) ?? '';
}

/// Normalizes Supabase/PostgREST row maps for safe model parsing.
Map<String, dynamic> supabaseRowToMap(dynamic row) {
  if (row is Map<String, dynamic>) return row;
  if (row is Map) {
    return row.map((key, value) => MapEntry(key.toString(), value));
  }
  throw ArgumentError('Expected a map row from Supabase, got ${row.runtimeType}');
}

List<Map<String, dynamic>> supabaseRowsToMaps(dynamic response) {
  if (response is! List) return const [];
  return response.map(supabaseRowToMap).toList();
}
