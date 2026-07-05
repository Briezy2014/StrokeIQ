import '../../core/utils/swim_time.dart';

class SwimGoal {
  const SwimGoal({
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
  final DateTime targetDate;
  final double? currentTime;

  factory SwimGoal.fromJson(Map<String, dynamic> json) {
    return SwimGoal(
      id: json['id'] as int?,
      swimmerName: json['swimmer_name'] as String? ?? '',
      event: json['event'] as String? ?? '',
      goalTime: SwimTime.parseStoredTime(json['goal_time']) ?? 0,
      course: json['course'] as String? ?? '',
      targetDate:
          DateTime.tryParse(json['target_date']?.toString() ?? '') ??
              DateTime.now(),
      currentTime: SwimTime.parseStoredTime(json['current_time']),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swimmer_name': swimmerName,
        'event': event,
        'current_time': currentTime,
        'goal_time': goalTime,
        'course': course,
        'target_date': _formatDate(targetDate),
      };

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
