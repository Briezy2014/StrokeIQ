import '../../core/utils/swim_time.dart';

class MeetResult {
  const MeetResult({
    this.id,
    required this.swimmerName,
    required this.meetName,
    required this.event,
    required this.swimTime,
    required this.course,
    required this.meetDate,
    this.notes,
  });

  final int? id;
  final String swimmerName;
  final String meetName;
  final String event;
  final double swimTime;
  final String course;
  final DateTime meetDate;
  final String? notes;

  factory MeetResult.fromJson(Map<String, dynamic> json) {
    return MeetResult(
      id: json['id'] as int?,
      swimmerName: json['swimmer_name'] as String? ?? '',
      meetName: json['meet_name'] as String? ?? '',
      event: json['event'] as String? ?? '',
      swimTime: SwimTime.parseStoredTime(json['swim_time']) ?? 0,
      course: json['course'] as String? ?? '',
      meetDate:
          DateTime.tryParse(json['meet_date']?.toString() ?? '') ??
              DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swimmer_name': swimmerName,
        'meet_name': meetName,
        'meet_date': _formatDate(meetDate),
        'event': event,
        'swim_time': swimTime,
        'course': course,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
      };

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
