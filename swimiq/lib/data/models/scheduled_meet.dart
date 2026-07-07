import 'dart:convert';

/// Upcoming team meet from a schedule scan or manual entry (not past [MeetResult]).
class ScheduledMeet {
  const ScheduledMeet({
    required this.externalId,
    required this.name,
    required this.startDate,
    this.endDate,
    this.location,
    this.categories = const [],
    this.source = 'photo-scan',
    this.course,
  });

  final String externalId;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final List<String> categories;
  final String source;
  final String? course;

  bool get isSwimMeet =>
      categories.isEmpty ||
      categories.any((c) => c.toLowerCase().contains('meet'));

  factory ScheduledMeet.fromJson(Map<String, dynamic> json) {
    return ScheduledMeet(
      externalId: json['external_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Meet',
      startDate: _parseDate(json['start_date'] ?? json['startDate']),
      endDate: json['end_date'] != null || json['endDate'] != null
          ? _parseDate(json['end_date'] ?? json['endDate'])
          : null,
      location: json['location'] as String?,
      categories: _stringList(json['categories']),
      source: json['source'] as String? ?? 'photo-scan',
      course: json['course'] as String?,
    );
  }

  factory ScheduledMeet.fromScanJson(Map<String, dynamic> json) {
    final name = (json['name'] as String? ?? 'Meet').trim();
    final start = _parseDate(json['start_date'] ?? json['startDate']);
    final id =
        '${name.toLowerCase()}_${start.year}${start.month}${start.day}'.hashCode
            .abs()
            .toString();
    return ScheduledMeet(
      externalId: id,
      name: name,
      startDate: start,
      endDate: json['end_date'] != null
          ? _parseDate(json['end_date'])
          : null,
      location: json['location'] as String?,
      categories: _stringList(json['categories'] ?? ['Swim Meet']),
      source: 'photo-scan',
      course: json['course'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'external_id': externalId,
        'name': name,
        'start_date': _formatDate(startDate),
        if (endDate != null) 'end_date': _formatDate(endDate!),
        if (location != null) 'location': location,
        'categories': categories,
        'source': source,
        if (course != null) 'course': course,
      };

  static List<ScheduledMeet> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ScheduledMeet.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String encodeList(List<ScheduledMeet> meets) {
    if (meets.isEmpty) return '';
    return jsonEncode(meets.map((m) => m.toJson()).toList());
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final text = raw.toString().trim();
    if (text.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
    final parts = text.split(RegExp(r'[/-]'));
    if (parts.length >= 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      var year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    }
    return DateTime.now();
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
