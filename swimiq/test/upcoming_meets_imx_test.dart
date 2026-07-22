import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/swim_schedule_entry.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  group('upcoming meets', () {
    test('nextMeet prefers future schedule over past results', () {
      final future = DateTime.now().add(const Duration(days: 14));
      final snapshot = PassportMetrics.build(
        swimmerName: 'Aspyn',
        profile: const SwimmerProfile(swimmerName: 'Aspyn'),
        raceLogs: const [],
        goals: const [],
        meetResults: [
          MeetResult(
            swimmerName: 'Aspyn',
            meetName: 'Old Invite',
            event: '50 Free',
            swimTime: 28.0,
            course: 'SCY',
            meetDate: DateTime(2026, 1, 1),
          ),
        ],
        videos: const [],
        videoAnalyses: const [],
        motivationalStandards: testMotivationalCatalog,
        schedules: [
          SwimScheduleEntry(
            swimmerName: 'Aspyn',
            scheduleType: SwimScheduleEntry.typeMeet,
            title: 'Summer Champs',
            scheduleDate: future,
          ),
        ],
      );

      expect(snapshot.nextMeet, contains('Summer Champs'));
      expect(snapshot.latestMeet, 'Old Invite');
    });

    test('latestMeet stays on past results when no upcoming schedule', () {
      final snapshot = PassportMetrics.build(
        swimmerName: 'Aspyn',
        profile: const SwimmerProfile(swimmerName: 'Aspyn'),
        raceLogs: const [],
        goals: const [],
        meetResults: [
          MeetResult(
            swimmerName: 'Aspyn',
            meetName: 'Winter Invite',
            event: '100 Fly',
            swimTime: 65.0,
            course: 'SCY',
            meetDate: DateTime(2026, 2, 1),
          ),
        ],
        videos: const [],
        videoAnalyses: const [],
        motivationalStandards: testMotivationalCatalog,
      );

      expect(snapshot.latestMeet, 'Winter Invite');
      expect(snapshot.nextMeet, 'No upcoming meet scheduled');
    });
  });

  group('IMX / IMR', () {
    test('uses Swimio values from passport profile notes', () {
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        athleteNotes: SwimmerProfile.composeAthleteNotes(
          imxScore: '3100',
          imrScore: '2100',
        ),
      );
      expect(
        PassportMetrics.imxScore(profile: profile),
        'IMX 3100 · IMR 2100',
      );
    });

    test('prompts to enter Swimio scores when missing', () {
      expect(
        PassportMetrics.imxScore(
          profile: const SwimmerProfile(swimmerName: 'Aspyn'),
        ),
        contains('Swimio'),
      );
    });
  });
}
