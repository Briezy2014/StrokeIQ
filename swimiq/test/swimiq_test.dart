import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/ai_swim_analysis_service.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/core/utils/swim_analytics.dart';
import 'package:swimiq/core/utils/swim_time.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/data/models/video_models.dart';

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

    test('parses exact Supabase row shape for reported UUID upload', () {
      final video = SwimVideo.fromSupabaseRow({
        'id': 'b526aa2a-c18f-451b-b8f0-e80947d50c20',
        'swimmer': null,
        'swimmer_name': 'Aspyn',
        'title': 'Denison 50 Fky',
        'stroke': 'Butterfly',
        'distance': '50',
        'course': 'LCM',
        'notes': 'Analyze reaction time',
        'video_url':
            'https://bryurwyeosbffvfpdpbv.supabase.co/storage/v1/object/public/swim-videos/Aspyn/528f7bd3.mov',
        'storage_path': 'Aspyn/528f7bd3-b5db-43d5-80a0-64190943c5c7.mov',
        'created_at': '2026-07-04T20:37:50.547436+00:00',
      });

      expect(video.id, 'b526aa2a-c18f-451b-b8f0-e80947d50c20');
      expect(video.swimmer, 'Aspyn');
      expect(video.distance, '50');
    });

    test('parses SwimVideoAnalysis UUID ids', () {
      final analysis = SwimVideoAnalysis.fromJson({
        'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'swim_video_id': 'b526aa2a-c18f-451b-b8f0-e80947d50c20',
        'swimmer': 'Aspyn',
        'summary': 'Good tempo',
        'strengths': 'Strong kick',
        'improvements': 'Earlier breath',
        'technique_score': '82',
        'pace_score': '78',
        'overall_score': '80',
      });

      expect(analysis.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(analysis.swimVideoId, 'b526aa2a-c18f-451b-b8f0-e80947d50c20');
      expect(analysis.overallScore, 80);
    });
  });

  group('AiSwimAnalysisService', () {
    test('builds notes-driven 50 Butterfly LCM coaching sections', () {
      const video = SwimVideo(
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/video.mov',
        title: 'Denison 50 Fly',
        stroke: 'Butterfly',
        distance: '50',
        course: 'LCM',
        notes: 'Analyze reaction time and faster breakout with 6 dolphin kicks',
      );

      final analysis = AiSwimAnalysisService().analyze(
        video: video,
        raceLogs: const [],
        goals: const [],
      );

      expect(analysis.analysisJson?['event'], '50 Butterfly LCM');
      expect(analysis.summary, contains('50 Butterfly LCM'));
      expect(analysis.summary, contains('Analyze reaction time'));
      expect(
        analysis.summary,
        contains(
          'V1 coaching analysis based on video metadata and user notes',
        ),
      );
      expect(analysis.summary, isNot(contains('consistent training history')));

      final sections = analysis.coachingSections;
      expect(sections['Reaction / dive'], contains('reaction time'));
      expect(sections['Breakout'], isNotEmpty);
      expect(sections['Streamline and underwater dolphin kicks'], contains('dolphin'));

      expect(analysis.topPriorities, isNotEmpty);
      expect(analysis.improvements, contains('Top 5 priorities'));
      expect(analysis.improvements, contains('USA Swimming motivational standards'));
    });

    test('hides integration test uploads from user-facing videos', () {
      const visible = SwimVideo(
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/real.mov',
        title: 'Denison 50 Fly',
      );
      const hidden = SwimVideo(
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/test.mov',
        title: 'Integration test video',
      );

      expect(visible.isUserFacing, isTrue);
      expect(hidden.isUserFacing, isFalse);
    });
  });

  group('PassportMetrics', () {
    test('builds passport snapshot from real swimmer data only', () {
      final snapshot = PassportMetrics.build(
        swimmerName: 'Aspyn',
        profile: const SwimmerProfile(
          swimmerName: 'Aspyn',
          preferredName: 'Aspyn',
          favoriteEvent: '50 Butterfly LCM',
        ),
        raceLogs: [
          RaceLog(
            swimmer: 'Aspyn',
            event: '50 Butterfly',
            distance: 50,
            stroke: 'Butterfly',
            course: 'LCM',
            timeSeconds: 32.5,
            date: DateTime(2026, 6, 1),
          ),
        ],
        goals: const [],
        meetResults: const [],
        videos: const [
          SwimVideo(
            swimmer: 'Aspyn',
            storagePath: 'Aspyn/fly.mov',
            title: 'Denison 50 Fly',
            stroke: 'Butterfly',
            distance: '50',
            course: 'LCM',
          ),
          SwimVideo(
            swimmer: 'Aspyn',
            storagePath: 'Aspyn/test.mov',
            title: 'Integration test video',
          ),
        ],
        videoAnalyses: const [],
        standards: const [],
      );

      expect(snapshot.displayName, 'Aspyn');
      expect(snapshot.currentFocus, '50 Butterfly LCM');
      expect(snapshot.videoCount, 1);
      expect(snapshot.personalBests.first, contains('50 Butterfly'));
      expect(snapshot.swimIqExplanation, contains('logged sessions'));
      expect(snapshot.swimIqExplanation, isNot(contains('consistent training')));
    });
  });
}
