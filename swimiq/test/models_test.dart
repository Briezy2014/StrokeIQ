import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/domain/models/goal.dart';
import 'package:swimiq/domain/models/race_log.dart';

void main() {
  group('RaceLog', () {
    test('parses streamlit complete-app row', () {
      final log = RaceLog.fromJson({
        'id': '1',
        'swimmer': 'user-123',
        'stroke': 'Freestyle',
        'distance': 100,
        'course': 'SCY',
        'time_seconds': 52.5,
        'event': '100 Freestyle',
        'date': '2026-07-01',
        'notes': 'Felt strong',
      });

      expect(log.stroke, 'Freestyle');
      expect(log.timeSeconds, 52.5);
      expect(log.date, DateTime(2026, 7, 1));
    });

    test('serializes insert row', () {
      final log = RaceLog(
        swimmer: 'user-123',
        stroke: 'Butterfly',
        distance: 50,
        course: 'SCY',
        timeSeconds: 28.4,
        event: '50 Butterfly',
        date: DateTime(2026, 7, 4),
      );

      final json = log.toInsertJson();
      expect(json['swimmer'], 'user-123');
      expect(json['time_seconds'], 28.4);
      expect(json['event'], '50 Butterfly');
    });
  });

  group('Goal', () {
    test('parses canonical and legacy columns', () {
      final canonical = Goal.fromJson({
        'swimmer': 'user-123',
        'stroke': 'IM',
        'distance_m': 200,
        'target_time_s': 120.5,
        'course': 'SCM',
        'target_date': '2026-08-01',
      });

      expect(canonical.stroke, 'IM');
      expect(canonical.targetTimeSeconds, 120.5);

      final legacy = Goal.fromJson({
        'swimmer_name': 'user-123',
        'event': '100 Butterfly',
        'goal_time': 65.2,
        'course': 'SCY',
      });

      expect(legacy.stroke, 'Butterfly');
      expect(legacy.targetTimeSeconds, 65.2);
    });
  });
}
