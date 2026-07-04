import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_analytics.dart';
import 'package:swimiq/core/utils/swim_time.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swim_video.dart';

void main() {
  group('SwimTime', () {
    test('parses seconds format', () {
      expect(SwimTime.toSeconds('35.43'), 35.43);
    });

    test('parses minutes format', () {
      expect(SwimTime.toSeconds('1:24.32'), 84.32);
    });

    test('formats short times', () {
      expect(SwimTime.fromSeconds(35.43), '35.43');
    });

    test('formats long times', () {
      expect(SwimTime.fromSeconds(84.32), '1:24.32');
    });
  });

  group('SwimAnalytics', () {
    final logs = [
      RaceLog(
        swimmer: 'Aspyn',
        event: '100 Freestyle',
        distance: 100,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: 60,
        date: DateTime(2026, 1, 1),
      ),
      RaceLog(
        swimmer: 'Aspyn',
        event: '100 Freestyle',
        distance: 100,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: 55,
        date: DateTime(2026, 2, 1),
      ),
    ];

    test('detects personal bests', () {
      final pbs = SwimAnalytics.personalBests(logs);
      expect(pbs.length, 1);
      expect(pbs.first.timeSeconds, 55);
    });

    test('calculates SwimIQ score', () {
      final score = SwimAnalytics.calculateSwimIqScore(
        raceLogs: logs,
        goals: [
          SwimGoal(
            swimmerName: 'Aspyn',
            event: '200 Butterfly',
            goalTime: 120,
            course: 'LCM',
            targetDate: DateTime(2026, 6, 1),
          ),
        ],
      );
      expect(score, 555);
    });
  });

  group('SwimVideo', () {
    test('parses uuid id and text distance from Supabase', () {
      final video = SwimVideo.fromJson({
        'id': '11bff29b-a27b-4ab1-8f62-97aea04d3f0b',
        'swimmer': 'Aspyn',
        'title': 'Denison 50 Fly',
        'stroke': 'Butterfly',
        'distance': '50',
        'course': 'LCM',
        'storage_path': 'Aspyn/video.mov',
        'video_url': 'https://example.com/video.mov',
      });

      expect(video.id, '11bff29b-a27b-4ab1-8f62-97aea04d3f0b');
      expect(video.swimmer, 'Aspyn');
      expect(video.distance, '50');
      expect(video.distanceMeters, 50);
    });

    test('falls back to swimmer_name when swimmer is null', () {
      final video = SwimVideo.fromJson({
        'id': '71f4f63b-99a6-4e50-b102-ea2c64f11e68',
        'swimmer': null,
        'swimmer_name': 'Aspyn',
        'distance': '100',
        'storage_path': 'Aspyn/video.mov',
      });

      expect(video.swimmer, 'Aspyn');
    });
  });
}
