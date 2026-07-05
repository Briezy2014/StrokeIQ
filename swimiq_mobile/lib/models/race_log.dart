/// One training session from the `race_logs` table.
class RaceLog {
  const RaceLog({
    this.id,
    required this.swimmer,
    required this.event,
    required this.stroke,
    required this.distance,
    required this.course,
    required this.timeSeconds,
    required this.date,
    this.notes,
  });

  final String? id;
  final String swimmer;
  final String event;
  final String stroke;
  final double distance;
  final String course;
  final double timeSeconds;
  final DateTime date;
  final String? notes;

  factory RaceLog.fromJson(Map<String, dynamic> json) {
    return RaceLog(
      id: json['id']?.toString(),
      swimmer: json['swimmer'] as String? ?? json['swimmer_name'] as String? ?? '',
      event: json['event'] as String? ?? '',
      stroke: json['stroke'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      course: json['course'] as String? ?? 'SCY',
      timeSeconds: (json['time_seconds'] as num).toDouble(),
      date: DateTime.parse(json['date'].toString()),
      notes: json['notes'] as String?,
    );
  }
}
