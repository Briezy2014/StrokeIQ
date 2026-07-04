class Goal {
  Goal({
    this.id,
    required this.swimmerName,
    required this.event,
    required this.goalTime,
    required this.course,
    required this.targetDate,
    this.currentTime,
  });

  final int? id;
  final String swimmerName;
  final String event;
  final double goalTime;
  final String course;
  final String targetDate;
  final double? currentTime;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int?,
      swimmerName: json['swimmer_name']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      goalTime: double.parse(json['goal_time'].toString()),
      course: json['course']?.toString() ?? '',
      targetDate: json['target_date']?.toString() ?? '',
      currentTime: json['current_time'] != null
          ? double.tryParse(json['current_time'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'swimmer_name': swimmerName,
      'event': event,
      'current_time': currentTime,
      'goal_time': goalTime,
      'course': course,
      'target_date': targetDate,
    };
  }
}
