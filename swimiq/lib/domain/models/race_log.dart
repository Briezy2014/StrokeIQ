import '../utils/personal_best_utils.dart';

class RaceLog {
  const RaceLog({
    this.id,
    required this.swimmer,
    required this.stroke,
    required this.distance,
    required this.course,
    required this.timeSeconds,
    required this.event,
    this.date,
    this.notes,
  });

  final String? id;
  final String swimmer;
  final String stroke;
  final int distance;
  final String course;
  final double timeSeconds;
  final String event;
  final DateTime? date;
  final String? notes;

  RaceLogEntry toEntry() {
    return RaceLogEntry(
      stroke: stroke,
      distance: distance,
      course: course,
      timeSeconds: timeSeconds,
      date: date,
    );
  }

  factory RaceLog.fromJson(Map<String, dynamic> json) {
    return RaceLog(
      id: json['id']?.toString(),
      swimmer: json['swimmer']?.toString() ?? '',
      stroke: json['stroke']?.toString() ?? 'Freestyle',
      distance: _parseDistance(json['distance']),
      course: json['course']?.toString() ?? 'SCY',
      timeSeconds: _parseTime(json['time_seconds']),
      event: json['event']?.toString() ?? '',
      date: _parseDate(json['date']),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'date': _formatDate(date ?? DateTime.now()),
      'swimmer': swimmer,
      'event': event,
      'distance': distance,
      'stroke': stroke,
      'course': course,
      'time_seconds': timeSeconds,
      'notes': notes ?? '',
    };
  }

  static int _parseDistance(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
