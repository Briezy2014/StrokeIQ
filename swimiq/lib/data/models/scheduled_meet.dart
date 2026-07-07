/// Upcoming team meet from a club schedule (distinct from past [MeetResult]).
class ScheduledMeet {
  const ScheduledMeet({
    required this.externalId,
    required this.name,
    required this.startDate,
    this.endDate,
    this.location,
    this.categories = const [],
    this.source = 'coa-gomotion',
  });

  final String externalId;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final List<String> categories;
  final String source;

  bool get isSwimMeet =>
      categories.any((c) => c.toLowerCase().contains('swim meet'));

  factory ScheduledMeet.fromCoaTeamEvent(Map<String, dynamic> json) {
    final id = _fieldValue(json['id']);
    final title = _fieldValue(json['title']) ?? 'Team event';
    final startRaw = _fieldValue(json['startDate']);
    final endRaw = _fieldValue(json['endDate']);
    final location = _fieldValue(json['location']);
    final categories = _fieldList(json['categories']);

    return ScheduledMeet(
      externalId: id ?? '',
      name: title,
      startDate: _parseDate(startRaw),
      endDate: endRaw == null ? null : _parseDate(endRaw),
      location: location,
      categories: categories,
    );
  }

  static String? _fieldValue(dynamic field) {
    if (field is Map) {
      final value = field['value'];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  static List<String> _fieldList(dynamic field) {
    if (field is Map) {
      final value = field['value'];
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
    }
    return const [];
  }

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
    return DateTime.now();
  }
}
