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
