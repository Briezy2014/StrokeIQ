import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/gemini_swim_analysis_service.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swim_video.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

void main() {
  group('GeminiSwimAnalysisService', () {
    test('buildRequestBody includes video and coach context', () {
      final video = SwimVideo(
        id: 'video-uuid',
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/clip.mp4',
        title: '50 Fly sprint',
        stroke: 'Butterfly',
        distance: '50',
        course: 'LCM',
        notes: 'Focus on breakout',
      );

      final body = GeminiSwimAnalysisService.buildRequestBody(
        video: video,
        raceLogs: [
          RaceLog(
            swimmer: 'Aspyn',
            event: '50 Fly',
            distance: 50,
            stroke: 'Butterfly',
            course: 'LCM',
            timeSeconds: 30.5,
            date: DateTime(2026, 6, 1),
          ),
        ],
        goals: [
          SwimGoal(
            swimmerName: 'Aspyn',
            event: '100 Fly',
            goalTime: 66,
            course: 'LCM',
            targetDate: DateTime(2026, 10, 1),
          ),
        ],
        profile: SwimmerProfile.fromJson({
          'swimmer_name': 'Aspyn',
          'preferred_name': 'Aspyn',
          'team': 'COA',
        }),
      );

      expect(body['storage_path'], 'Aspyn/clip.mp4');
      expect(body['event_label'], '50 Butterfly LCM');
      expect(body['coach_context'], isA<Map>());
      final ctx = body['coach_context'] as Map;
      expect(ctx['team'], 'COA');
      expect(ctx['personal_bests'], isNotEmpty);
      expect(ctx['goals'], isNotEmpty);
    });

    test('buildRequestBody uses fastest PB per event, not first log', () {
      final video = SwimVideo(
        id: 'video-uuid',
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/clip.mp4',
        title: '50 Fly sprint',
        stroke: 'Butterfly',
        distance: '50',
        course: 'LCM',
      );

      final body = GeminiSwimAnalysisService.buildRequestBody(
        video: video,
        raceLogs: [
          RaceLog(
            swimmer: 'Aspyn',
            event: '50 Fly',
            distance: 50,
            stroke: 'Butterfly',
            course: 'LCM',
            timeSeconds: 32.0,
            date: DateTime(2026, 5, 1),
          ),
          RaceLog(
            swimmer: 'Aspyn',
            event: '50 Fly',
            distance: 50,
            stroke: 'Butterfly',
            course: 'LCM',
            timeSeconds: 30.1,
            date: DateTime(2026, 6, 1),
          ),
        ],
        goals: const [],
        profile: null,
      );

      final ctx = body['coach_context'] as Map;
      final pbs = (ctx['personal_bests'] as List).cast<String>();
      expect(pbs.single, contains('30.1'));
      expect(pbs.single, isNot(contains('32')));
    });

    test('parseAnalysisResponse maps Gemini JSON to SwimVideoAnalysis', () {
      final analysis = GeminiSwimAnalysisService.parseAnalysisResponse({
        'swim_video_id': 'video-uuid',
        'swimmer': 'Aspyn',
        'summary': '50 Butterfly LCM\nGemini summary',
        'strengths': 'Strong kick',
        'improvements': 'Top 3 priorities\n• Head position',
        'technique_score': 82,
        'pace_score': 78,
        'overall_score': 80,
        'analysis_json': {
          'engine': 'swimiq-v2-gemini',
          'model': 'gemini-2.0-flash',
          'top_3_priorities': ['Head position', 'Kick tempo', 'Finish'],
        },
      });

      expect(analysis.isGeminiEngine, isTrue);
      expect(analysis.isLegacyRulesEngine, isFalse);
      expect(analysis.overallScore, 80);
      expect(analysis.topPriorities.length, 3);
      expect(analysis.summary, contains('Gemini summary'));
    });
  });
}
