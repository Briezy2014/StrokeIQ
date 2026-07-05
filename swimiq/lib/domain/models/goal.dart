class Goal {
  const Goal({
    this.id,
    required this.swimmer,
    required this.stroke,
    required this.distance,
    required this.targetTimeSeconds,
    required this.course,
    this.targetDate,
  });

  final String? id;
  final String swimmer;
  final String stroke;
  final int distance;
  final double targetTimeSeconds;
  final String course;
  final DateTime? targetDate;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id']?.toString(),
      swimmer: json['swimmer']?.toString() ?? json['swimmer_name']?.toString() ?? '',
      stroke: json['stroke']?.toString() ?? _strokeFromEvent(json['event']?.toString()),
      distance: _parseDistance(json),
      targetTimeSeconds: _parseTargetTime(json),
      course: json['course']?.toString() ?? 'SCY',
      targetDate: _parseDate(json['target_date']),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'swimmer': swimmer,
      'stroke': stroke,
      'distance_m': distance,
      'target_time_s': targetTimeSeconds,
      'course': course,
      'target_date': _formatDate(targetDate),
    };
  }

  static int _parseDistance(Map<String, dynamic> json) {
    final distance = json['distance_m'] ?? json['distance'];
    if (distance is int) return distance;
    if (distance is num) return distance.toInt();
    return 0;
  }

  static double _parseTargetTime(Map<String, dynamic> json) {
    final value = json['target_time_s'] ?? json['goal_time'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _strokeFromEvent(String? event) {
    if (event == null || event.isEmpty) return 'Freestyle';
    for (final stroke in const [
      'Freestyle',
      'Backstroke',
      'Breaststroke',
      'Butterfly',
      'IM',
    ]) {
      if (event.contains(stroke)) return stroke;
    }
    return 'Freestyle';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
