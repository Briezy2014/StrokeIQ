import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_analytics.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';

void main() {
  test('personalBestsUnified includes faster meet result', () {
    final raceLogs = [
      RaceLog(
        swimmer: 'Aspyn',
        event: '200 Butterfly',
        distance: 200,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: 140,
        date: DateTime(2026, 5, 1),
      ),
    ];
    final meetResults = [
      MeetResult(
        swimmerName: 'Aspyn',
        meetName: 'Summer Invite',
        event: '200 Fly',
        swimTime: 130,
        course: 'LCM',
        meetDate: DateTime(2026, 6, 27),
      ),
    ];

    final pbs = SwimAnalytics.personalBestsUnified(
      raceLogs: raceLogs,
      meetResults: meetResults,
    );

    expect(pbs.length, 1);
    expect(pbs.first.timeSeconds, 130);
    expect(pbs.first.source.name, 'meet');
  });

  test('personalBestsUnified keeps separate courses', () {
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

    final pbs = SwimAnalytics.personalBestsUnified(
      raceLogs: const [],
      meetResults: meetResults,
    );

    expect(pbs.length, 2);
  });
}
