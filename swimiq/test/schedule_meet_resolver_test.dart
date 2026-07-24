import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/race_intelligence_service.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/core/utils/schedule_meet_resolver.dart';
import 'package:swimiq/data/models/swim_schedule_entry.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('parses schedule_date as local calendar day from UTC midnight ISO', () {
    final entry = SwimScheduleEntry.fromJson({
      'swimmer_name': 'Aspyn',
      'schedule_type': 'MEET',
      'title': 'COA Invite',
      'schedule_date': '2026-08-02T00:00:00.000Z',
      'start_time': '9:00 AM',
      'events_line': '100 Fly',
    });

    expect(entry.isMeet, isTrue);
    expect(entry.scheduleDate, DateTime(2026, 8, 2));
    expect(entry.scheduleDate.isUtc, isFalse);
  });

  test('passport and race intelligence resolve the same upcoming meet', () {
    final now = DateTime(2026, 7, 24, 12);
    final data = SwimmerData(
      raceLogs: const [],
      goals: const [],
      meetResults: const [],
      schedules: [
        SwimScheduleEntry(
          swimmerName: 'Aspyn',
          scheduleType: SwimScheduleEntry.typeMeet,
          title: 'Summer Invite',
          scheduleDate: DateTime(2026, 7, 28),
          startTime: '8:30 AM',
          eventsLine: '50 Fly, 100 Fly',
        ),
      ],
      motivationalStandards: testMotivationalCatalog,
    );

    final snapshot = PassportMetrics.build(
      swimmerName: 'Aspyn',
      profile: null,
      raceLogs: data.raceLogs,
      goals: data.goals,
      meetResults: data.meetResults,
      videos: const [],
      videoAnalyses: const [],
      motivationalStandards: data.motivationalStandards,
      schedules: data.schedules,
      now: now,
    );
    final plan = RaceIntelligenceService.build(
      data: data,
      swimmer: 'Aspyn',
    );
    final resolved = ScheduleMeetResolver.nextMeetOrRace(
      data.schedules,
      now: now,
    );

    expect(resolved?.title, 'Summer Invite');
    expect(snapshot.nextMeet, contains('Summer Invite'));
    expect(snapshot.nextMeet, contains('8:30 AM'));
    expect(plan.syncedToSchedule, isTrue);
    expect(plan.meetTitle, snapshot.nextMeet.split(' · ').first);
  });

  test('falls back to most recent meet so passport stays synced', () {
    final now = DateTime(2026, 7, 24, 12);
    final schedules = [
      SwimScheduleEntry(
        swimmerName: 'Aspyn',
        scheduleType: SwimScheduleEntry.typeMeet,
        title: 'June Invite',
        scheduleDate: DateTime(2026, 6, 10),
        startTime: '10:00 AM',
      ),
    ];

    final entry = ScheduleMeetResolver.nextMeetOrRace(schedules, now: now);
    expect(entry?.title, 'June Invite');
    expect(
      PassportMetrics.nextMeet(schedules: schedules, now: now),
      contains('June Invite'),
    );
  });
}
