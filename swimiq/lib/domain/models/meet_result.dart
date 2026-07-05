class MeetResult {
  const MeetResult({
    this.id,
    required this.swimmer,
    required this.meetName,
    required this.event,
    required this.timeSeconds,
    required this.course,
    this.meetDate,
  });

  final String? id;
  final String swimmer;
  final String meetName;
  final String event;
  final double timeSeconds;
  final String course;
  final DateTime? meetDate;

  factory MeetResult.fromJson(Map<String, dynamic> json) {
    return MeetResult(
      id: json['id']?.toString(),
      swimmer: json['swimmer']?.toString() ?? json['swimmer_name']?.toString() ?? '',
      meetName: json['meet_name']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      timeSeconds: _parseTime(json['time_s'] ?? json['swim_time']),
      course: json['course']?.toString() ?? 'SCY',
      meetDate: _parseDate(json['meet_date']),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'swimmer': swimmer,
      'meet_name': meetName,
      'meet_date': _formatDate(meetDate ?? DateTime.now()),
      'event': event,
      'time_s': timeSeconds,
      'course': course,
    };
  }

  static double _parseTime(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
