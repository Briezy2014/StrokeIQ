/// Upcoming practice, meet, or race slot saved by the athlete/coach.
class SwimScheduleEntry {
  const SwimScheduleEntry({
    this.id,
    required this.swimmerName,
    required this.scheduleType,
    required this.title,
    required this.scheduleDate,
    this.startTime,
    this.location,
    this.eventsLine,
    this.notes,
    this.createdAt,
  });

  static const typePractice = 'practice';
  static const typeMeet = 'meet';
  static const typeRace = 'race';

  final int? id;
  final String swimmerName;
  final String scheduleType;
  final String title;
  final DateTime scheduleDate;
  final String? startTime;
  final String? location;
  final String? eventsLine;
  final String? notes;
  final DateTime? createdAt;

  bool get isPractice => scheduleType == typePractice;
  bool get isMeet => scheduleType == typeMeet;
  bool get isRace => scheduleType == typeRace;

  String get typeLabel {
    switch (scheduleType) {
      case typeMeet:
        return 'Meet';
      case typeRace:
        return 'Race result';
      default:
        return 'Practice';
    }
  }

  factory SwimScheduleEntry.fromJson(Map<String, dynamic> json) {
    return SwimScheduleEntry(
      id: _parseId(json['id']),
      swimmerName: json['swimmer_name']?.toString() ?? '',
      scheduleType: json['schedule_type']?.toString() ?? typePractice,
      title: json['title']?.toString() ?? '',
      scheduleDate: DateTime.tryParse(json['schedule_date']?.toString() ?? '') ??
          DateTime.now(),
      startTime: _nullableText(json['start_time']),
      location: _nullableText(json['location']),
      eventsLine: _nullableText(json['events_line']),
      notes: _nullableText(json['notes']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toInsertJson() {
    final start = startTime?.trim();
    final place = location?.trim();
    final events = eventsLine?.trim();
    final note = notes?.trim();
    return {
      'swimmer_name': swimmerName,
      'schedule_type': scheduleType,
      'title': title,
      'schedule_date': _formatDate(scheduleDate),
      if (start != null && start.isNotEmpty) 'start_time': start,
      if (place != null && place.isNotEmpty) 'location': place,
      if (events != null && events.isNotEmpty) 'events_line': events,
      if (note != null && note.isNotEmpty) 'notes': note,
    };
  }

  SwimScheduleEntry copyWith({
    int? id,
    String? swimmerName,
    String? scheduleType,
    String? title,
    DateTime? scheduleDate,
    String? startTime,
    String? location,
    String? eventsLine,
    String? notes,
    DateTime? createdAt,
  }) {
    return SwimScheduleEntry(
      id: id ?? this.id,
      swimmerName: swimmerName ?? this.swimmerName,
      scheduleType: scheduleType ?? this.scheduleType,
      title: title ?? this.title,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      startTime: startTime ?? this.startTime,
      location: location ?? this.location,
      eventsLine: eventsLine ?? this.eventsLine,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _nullableText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
