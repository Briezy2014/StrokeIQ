import '../recruiting/meet_history_analytics.dart';
import '../../data/models/swim_schedule_entry.dart';

/// Single source of truth for “next meet/race” across Passport + Race Intelligence.
abstract final class ScheduleMeetResolver {
  ScheduleMeetResolver._();

  /// Next meet/race from Log → Meets.
  ///
  /// Prefers today-or-later. If none remain, falls back to the most recent
  /// meet/race so Passport and Race Intelligence stay synced to the same entry.
  static SwimScheduleEntry? nextMeetOrRace(
    List<SwimScheduleEntry> schedules, {
    DateTime? now,
  }) {
    if (schedules.isEmpty) return null;
    final clock = now ?? DateTime.now();
    final startOfToday = DateTime(clock.year, clock.month, clock.day);

    bool isFromTodayOn(SwimScheduleEntry entry) {
      final day = dateOnly(entry.scheduleDate);
      return !day.isBefore(startOfToday);
    }

    int compareEntries(SwimScheduleEntry a, SwimScheduleEntry b) {
      final byDate = dateOnly(a.scheduleDate).compareTo(dateOnly(b.scheduleDate));
      if (byDate != 0) return byDate;
      return (a.startTime ?? '').compareTo(b.startTime ?? '');
    }

    final meetLike = schedules.where(_isMeetOrRace).toList();
    final futureMeets = meetLike.where(isFromTodayOn).toList()
      ..sort(compareEntries);
    if (futureMeets.isNotEmpty) return futureMeets.first;

    if (meetLike.isNotEmpty) {
      meetLike.sort(compareEntries);
      return meetLike.last;
    }

    return null;
  }

  /// Compact passport / status-chip label for [entry].
  static String formatLabel(
    SwimScheduleEntry? entry, {
    String emptyLabel = 'None scheduled',
  }) {
    if (entry == null) return emptyLabel;
    final title = entry.title.trim();
    if (title.isEmpty) return emptyLabel;
    final date = _formatShortDate(entry.scheduleDate);
    final start = entry.startTime?.trim();
    if (start != null && start.isNotEmpty) {
      return '$title · $date · $start';
    }
    return '$title · $date';
  }

  /// Longer sync line used under the recruiting card.
  static String formatSyncLine(SwimScheduleEntry? entry) {
    if (entry == null) return 'Add an upcoming meet on Log → Meets to sync';
    final base = formatLabel(entry);
    final events = entry.eventsLine?.trim();
    if (events == null || events.isEmpty) return base;
    final firstEvent = events
        .split(RegExp(r'[\n,;|/]+'))
        .map((part) => part.trim())
        .firstWhere((part) => part.isNotEmpty, orElse: () => '');
    if (firstEvent.isEmpty) return base;
    return '$base · $firstEvent';
  }

  static bool isUpcoming(
    SwimScheduleEntry entry, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final startOfToday = DateTime(clock.year, clock.month, clock.day);
    return !dateOnly(entry.scheduleDate).isBefore(startOfToday);
  }

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _isMeetOrRace(SwimScheduleEntry entry) {
    if (!entry.isMeet && !entry.isRace) return false;
    if (MeetHistoryAnalytics.isSyntheticMeetName(entry.title)) return false;
    return true;
  }

  static String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dateOnly(date);
    return '${months[day.month - 1]} ${day.day}';
  }
}
