import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/swim_goal.dart';

void main() {
  group('PassportMetrics meet labels', () {
    test('lastMeetResult uses most recent meet result', () {
      final label = PassportMetrics.lastMeetResult([
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Summer Invite',
          event: '50 Fly',
          swimTime: 30,
          course: 'SCY',
          meetDate: DateTime(2026, 6, 1),
        ),
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Districts',
          event: '100 Fly',
          swimTime: 66,
          course: 'SCY',
          meetDate: DateTime(2026, 7, 1),
        ),
      ]);

      expect(label, contains('Districts'));
      expect(label, contains('7/1/2026'));
    });

    test('upcomingMeet uses nearest future goal', () {
      final label = PassportMetrics.upcomingMeet([
        SwimGoal(
          swimmerName: 'Aspyn',
          event: '100 Fly',
          goalTime: 66,
          course: 'SCY',
          targetDate: DateTime.now().add(const Duration(days: 30)),
        ),
      ]);

      expect(label, contains('100 Fly'));
      expect(label, contains('SCY'));
    });
  });
}
