import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/swim_schedule_entry.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('passportSnapshot uses upcoming schedule meet for nextMeet', () {
    final meetDate = DateTime.now().add(const Duration(days: 4));
    final data = SwimmerData(
      raceLogs: const [],
      goals: const [],
      meetResults: const [],
      schedules: [
        SwimScheduleEntry(
          swimmerName: 'Aspyn',
          scheduleType: SwimScheduleEntry.typeMeet,
          title: 'Summer Invite',
          scheduleDate: meetDate,
          startTime: '8:30 AM',
          eventsLine: '50 Free, 100 Fly',
        ),
      ],
      motivationalStandards: testMotivationalCatalog,
    );

    final snapshot = data.passportSnapshot('Aspyn');
    expect(snapshot.nextMeet, isNot(PassportMetrics.noUpcomingMeetLabel));
    expect(snapshot.nextMeet, contains('Summer Invite'));
    expect(snapshot.nextMeet, contains('8:30 AM'));
  });

  test('swimIqScore matches passportSnapshot and includes meet results', () {
    final data = SwimmerData(
      raceLogs: const [],
      goals: const [],
      meetResults: [
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Spring Invite',
          event: '100 Fly',
          swimTime: 68.2,
          course: 'SCY',
          meetDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      motivationalStandards: testMotivationalCatalog,
    );

    final snapshot = data.passportSnapshot('Aspyn');
    expect(data.swimIqScore, snapshot.swimIqScore);
    expect(data.swimIqScore, greaterThan(0));
  });
}
