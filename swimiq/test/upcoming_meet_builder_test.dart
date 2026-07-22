import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/upcoming_meet_builder.dart';
import 'package:swimiq/data/models/swim_schedule_entry.dart';

void main() {
  group('buildUpcomingMeetEntries', () {
    test('creates one row per day with shared meet title', () {
      final entries = buildUpcomingMeetEntries(
        swimmerName: 'Aspyn',
        title: 'Central Zone',
        location: 'OSU',
        notes: 'Bring snacks',
        days: [
          UpcomingMeetDayInput(
            date: DateTime(2026, 8, 1),
            startTime: '8:00 AM',
            eventsLine: '50 Free\n100 Fly',
          ),
          UpcomingMeetDayInput(
            date: DateTime(2026, 8, 2),
            startTime: '9:00 AM',
            eventsLine: '200 IM',
          ),
          UpcomingMeetDayInput(
            date: DateTime(2026, 8, 3),
            startTime: '7:30 AM',
            eventsLine: '100 Free',
          ),
        ],
      );

      expect(entries, hasLength(3));
      expect(entries.every((e) => e.title == 'Central Zone'), isTrue);
      expect(entries.every((e) => e.isMeet), isTrue);
      expect(entries.every((e) => e.location == 'OSU'), isTrue);
      expect(entries[0].eventsLine, contains('50 Free'));
      expect(entries[1].eventsLine, '200 IM');
      expect(entries[2].startTime, '7:30 AM');
      expect(entries[0].notes, contains('Day 1 of 3'));
      expect(entries[2].notes, contains('Bring snacks'));
    });

    test('single-day meet keeps shared notes without day tag', () {
      final entries = buildUpcomingMeetEntries(
        swimmerName: 'Aspyn',
        title: 'Dual Meet',
        notes: 'Lane 4',
        days: [
          UpcomingMeetDayInput(
            date: DateTime(2026, 8, 10),
            startTime: '5:00 PM',
            eventsLine: '50 Fly',
          ),
        ],
      );

      expect(entries, hasLength(1));
      expect(entries.single.notes, 'Lane 4');
    });
  });

  group('meetSeriesDays', () {
    test('aggregates same-title days for race intelligence', () {
      final day1 = SwimScheduleEntry(
        swimmerName: 'Aspyn',
        scheduleType: SwimScheduleEntry.typeMeet,
        title: 'Invite',
        scheduleDate: DateTime(2026, 9, 12),
        eventsLine: '50 Free',
      );
      final day2 = SwimScheduleEntry(
        swimmerName: 'Aspyn',
        scheduleType: SwimScheduleEntry.typeMeet,
        title: 'Invite',
        scheduleDate: DateTime(2026, 9, 13),
        eventsLine: '100 Fly',
      );
      final other = SwimScheduleEntry(
        swimmerName: 'Aspyn',
        scheduleType: SwimScheduleEntry.typeMeet,
        title: 'Other Meet',
        scheduleDate: DateTime(2026, 9, 14),
        eventsLine: '200 Free',
      );

      final series = meetSeriesDays(
        schedules: [day1, day2, other],
        anchor: day1,
        now: DateTime(2026, 9, 1),
      );

      expect(series, hasLength(2));
      expect(series.map((e) => e.eventsLine), containsAll(['50 Free', '100 Fly']));
    });
  });
}
