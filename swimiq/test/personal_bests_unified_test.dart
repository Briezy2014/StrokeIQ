import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_analytics.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';

void main() {
  test('personalBestsFromMeets ignores training sessions', () {
    final raceLogs = [
      RaceLog(
        swimmer: 'Aspyn',
        event: '200 Butterfly',
        distance: 200,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: 120,
        date: DateTime(2026, 5, 1),
      ),
    ];

    final pbs = SwimAnalytics.personalBestsFromMeets(meetResults: const []);

    expect(pbs, isEmpty);
    expect(
      SwimAnalytics.personalBestsFromMeets(
        meetResults: [
          MeetResult(
            swimmerName: 'Aspyn',
            meetName: 'Summer Invite',
            event: '200 Fly',
            swimTime: 130,
            course: 'LCM',
            meetDate: DateTime(2026, 6, 27),
          ),
        ],
      ).first.timeSeconds,
      130,
    );
    expect(raceLogs, isNotEmpty);
  });

  test('personalBestsFromMeets keeps fastest time per event', () {
    final meetResults = [
      MeetResult(
        swimmerName: 'Aspyn',
        meetName: 'Invite',
        event: '200 Butterfly',
        swimTime: 130,
        course: 'LCM',
        meetDate: DateTime(2026, 6, 27),
      ),
      MeetResult(
        swimmerName: 'Aspyn',
        meetName: 'Championships',
        event: '200 Butterfly',
        swimTime: 125,
        course: 'LCM',
        meetDate: DateTime(2026, 7, 1),
      ),
    ];

    final pbs = SwimAnalytics.personalBestsFromMeets(meetResults: meetResults);

    expect(pbs.length, 1);
    expect(pbs.first.timeSeconds, 125);
    expect(pbs.first.source.name, 'meet');
  });

  test('personalBestsFromMeets keeps separate courses', () {
    final meetResults = [
      MeetResult(
        swimmerName: 'Aspyn',
        meetName: 'Invite',
        event: '200 Butterfly',
        swimTime: 130,
        course: 'LCM',
        meetDate: DateTime(2026, 6, 27),
      ),
      MeetResult(
        swimmerName: 'Aspyn',
        meetName: 'Dual Meet',
        event: '200 Butterfly',
        swimTime: 125,
        course: 'SCY',
        meetDate: DateTime(2026, 7, 1),
      ),
    ];

    final pbs = SwimAnalytics.personalBestsFromMeets(meetResults: meetResults);

    expect(pbs.length, 2);
  });
}
