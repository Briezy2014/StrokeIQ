import '../../core/utils/swim_time.dart';

class RaceLog {
  const RaceLog({
    this.id,
    required this.swimmer,
    required this.event,
    required this.distance,
    required this.stroke,
    required this.course,
    required this.timeSeconds,
    required this.date,
    this.notes,
  });

  final int? id;
  final String swimmer;
  final String event;
  final int distance;
  final String stroke;
  final String course;
  final double timeSeconds;
  final DateTime date;
  final String? notes;

  factory RaceLog.fromJson(Map<String, dynamic> json) {
    final time = SwimTime.parseStoredTime(json['time_seconds']);
    return RaceLog(
      id: json['id'] as int?,
      swimmer: json['swimmer'] as String? ?? '',
      event: json['event'] as String? ?? '',
      distance: (json['distance'] as num?)?.toInt() ?? 0,
      stroke: json['stroke'] as String? ?? '',
      course: json['course'] as String? ?? '',
      timeSeconds: time ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swimmer': swimmer,
        'event': event,
        'distance': distance,
        'stroke': stroke,
        'course': course,
        'time_seconds': timeSeconds,
        'date': _formatDate(date),
        'notes': notes ?? '',
      };

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
