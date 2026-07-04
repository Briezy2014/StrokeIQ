class RaceLog {
  RaceLog({
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
  final String date;
  final String? notes;

  factory RaceLog.fromJson(Map<String, dynamic> json) {
    return RaceLog(
      id: json['id'] as int?,
      swimmer: json['swimmer']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      distance: (json['distance'] as num?)?.toInt() ?? 0,
      stroke: json['stroke']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      timeSeconds: double.parse(json['time_seconds'].toString()),
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'swimmer': swimmer,
      'event': event,
      'distance': distance,
      'stroke': stroke,
      'course': course,
      'time_seconds': timeSeconds,
      'date': date,
      'notes': notes,
    };
  }
}
