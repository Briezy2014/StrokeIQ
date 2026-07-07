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
      id: json['id'] as int?,
      swimmerName: json['swimmer_name'] as String? ?? '',
      scheduleType: json['schedule_type'] as String? ?? typePractice,
      title: json['title'] as String? ?? '',
      scheduleDate: DateTime.tryParse(json['schedule_date']?.toString() ?? '') ??
          DateTime.now(),
      startTime: _nullableText(json['start_time']),
      location: _nullableText(json['location']),
      eventsLine: _nullableText(json['events_line']),
      notes: _nullableText(json['notes']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swimmer_name': swimmerName,
        'schedule_type': scheduleType,
        'title': title,
        'schedule_date': _formatDate(scheduleDate),
        if (startTime != null && startTime!.trim().isNotEmpty)
          'start_time': startTime!.trim(),
        if (location != null && location!.trim().isNotEmpty)
          'location': location!.trim(),
        if (eventsLine != null && eventsLine!.trim().isNotEmpty)
          'events_line': eventsLine!.trim(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };

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
