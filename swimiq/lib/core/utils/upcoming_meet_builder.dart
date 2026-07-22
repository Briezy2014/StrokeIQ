import '../../data/models/swim_schedule_entry.dart';

/// One calendar day inside an upcoming meet (meets can span multiple days).
class UpcomingMeetDayInput {
  const UpcomingMeetDayInput({
    required this.date,
    this.startTime,
    this.eventsLine,
  });

  final DateTime date;
  final String? startTime;
  final String? eventsLine;
}

/// Builds one [SwimScheduleEntry] per meet day so Race Intelligence can sync
/// start times and events across multi-day meets.
List<SwimScheduleEntry> buildUpcomingMeetEntries({
  required String swimmerName,
  required String title,
  required List<UpcomingMeetDayInput> days,
  String? location,
  String? notes,
}) {
  final trimmedTitle = title.trim();
  if (trimmedTitle.isEmpty) {
    throw ArgumentError('Meet name is required.');
  }
  if (days.isEmpty) {
    throw ArgumentError('At least one meet day is required.');
  }

  final sorted = [...days]
    ..sort((a, b) => DateTime(a.date.year, a.date.month, a.date.day)
        .compareTo(DateTime(b.date.year, b.date.month, b.date.day)));

  final totalDays = sorted.length;
  return [
    for (var i = 0; i < sorted.length; i++)
      SwimScheduleEntry(
        swimmerName: swimmerName,
        scheduleType: SwimScheduleEntry.typeMeet,
        title: trimmedTitle,
        scheduleDate: DateTime(
          sorted[i].date.year,
          sorted[i].date.month,
          sorted[i].date.day,
        ),
        startTime: _optional(sorted[i].startTime),
        location: _optional(location),
        eventsLine: _optional(sorted[i].eventsLine),
        notes: _dayNotes(
          dayIndex: i + 1,
          totalDays: totalDays,
          sharedNotes: notes,
        ),
      ),
  ];
}

/// Future meet/race days that share the same title as [anchor] (multi-day series).
List<SwimScheduleEntry> meetSeriesDays({
  required List<SwimScheduleEntry> schedules,
  required SwimScheduleEntry anchor,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final startOfToday = DateTime(clock.year, clock.month, clock.day);
  final key = anchor.title.trim().toLowerCase();
  if (key.isEmpty) return [anchor];

  final series = schedules.where((entry) {
    if (!entry.isMeet && !entry.isRace) return false;
    if (entry.title.trim().toLowerCase() != key) return false;
    final day = DateTime(
      entry.scheduleDate.year,
      entry.scheduleDate.month,
      entry.scheduleDate.day,
    );
    // Keep past days of an in-progress meet so Day 2/3 still see full event list.
    final anchorDay = DateTime(
      anchor.scheduleDate.year,
      anchor.scheduleDate.month,
      anchor.scheduleDate.day,
    );
    final spanStart = anchorDay.subtract(const Duration(days: 6));
    final spanEnd = anchorDay.add(const Duration(days: 6));
    if (day.isBefore(spanStart) || day.isAfter(spanEnd)) return false;
    // Drop days more than a week before today unless they are the anchor.
    if (day.isBefore(startOfToday.subtract(const Duration(days: 1))) &&
        day != anchorDay) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) {
      final byDate = a.scheduleDate.compareTo(b.scheduleDate);
      if (byDate != 0) return byDate;
      return (a.startTime ?? '').compareTo(b.startTime ?? '');
    });

  return series.isEmpty ? [anchor] : series;
}

String? _optional(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _dayNotes({
  required int dayIndex,
  required int totalDays,
  required String? sharedNotes,
}) {
  final shared = _optional(sharedNotes);
  if (totalDays <= 1) return shared;
  final dayTag = 'Day $dayIndex of $totalDays';
  if (shared == null) return dayTag;
  return '$dayTag\n$shared';
}
