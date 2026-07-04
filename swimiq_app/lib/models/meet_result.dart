class MeetResult {
  MeetResult({
    this.id,
    required this.swimmerName,
    required this.meetName,
    required this.meetDate,
    required this.event,
    required this.swimTime,
    required this.course,
    this.notes,
  });

  final int? id;
  final String swimmerName;
  final String meetName;
  final String meetDate;
  final String event;
  final double swimTime;
  final String course;
  final String? notes;

  factory MeetResult.fromJson(Map<String, dynamic> json) {
    return MeetResult(
      id: json['id'] as int?,
      swimmerName: json['swimmer_name']?.toString() ?? '',
      meetName: json['meet_name']?.toString() ?? '',
      meetDate: json['meet_date']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      swimTime: double.parse(json['swim_time'].toString()),
      course: json['course']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'swimmer_name': swimmerName,
      'meet_name': meetName,
      'meet_date': meetDate,
      'event': event,
      'swim_time': swimTime,
      'course': course,
      'notes': notes,
    };
  }
}
