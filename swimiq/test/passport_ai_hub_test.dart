import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/passport_ai_recommendation.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swim_video.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

SwimmerData _baseData({
  List<SwimVideo> videos = const [],
  List<SwimVideoAnalysis> analyses = const [],
}) {
  return SwimmerData(
    raceLogs: [
      RaceLog(
        swimmer: 'Aspyn',
        event: '50 Fly',
        distance: 50,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: 30,
        date: DateTime(2026, 6, 1),
      ),
    ],
    goals: [
      SwimGoal(
        swimmerName: 'Aspyn',
        event: '100 Fly',
        goalTime: 66,
        course: 'SCY',
        targetDate: DateTime(2026, 10, 1),
      ),
    ],
    meetResults: [
      MeetResult(
        swimmerName: 'Aspyn',
        meetName: 'Test Meet',
        event: '50 Fly',
        swimTime: 30,
        course: 'SCY',
        meetDate: DateTime(2026, 6, 1),
      ),
    ],
    profile: const SwimmerProfile(
      id: 4,
      swimmerName: 'Aspyn',
      preferredName: 'Aspyn',
      primaryStroke: 'Butterfly',
    ),
    videos: videos,
    videoAnalyses: analyses,
    motivationalStandards: testMotivationalCatalog,
  );
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  group('PassportAiRecommendation', () {
    test('recommends Video Lab when no videos exist', () {
      final recommendation = PassportAiRecommendation.build(
        data: _baseData(),
        swimmer: 'Aspyn',
      );

      expect(recommendation.destination, PassportHubDestination.videoLab);
      expect(recommendation.detail, contains('Video Lab'));
      expect(recommendation.engineLabel, contains('SwimIQ AI Coach'));
    });

    test('recommends analysis for unanalyzed uploads', () {
      final recommendation = PassportAiRecommendation.build(
        data: _baseData(
          videos: [
            SwimVideo(
              id: 'video-1',
              swimmer: 'Aspyn',
              storagePath: 'Aspyn/video-1.mp4',
              title: 'District Finals',
              stroke: 'Butterfly',
              distance: '50',
              course: 'SCY',
            ),
          ],
        ),
        swimmer: 'Aspyn',
      );

      expect(recommendation.headline, contains('Recommended next AI analysis'));
      expect(recommendation.actionLabel, contains('Video Lab'));
      expect(recommendation.suggestedEvent, contains('50'));
      expect(recommendation.detail.toLowerCase(), isNot(contains('race notes')));
      expect(recommendation.detail.toLowerCase(), contains('automatically'));
    });

    test('prefers existing analysis over another unanalyzed upload', () {
      final recommendation = PassportAiRecommendation.build(
        data: _baseData(
          videos: [
            SwimVideo(
              id: 'video-done',
              swimmer: 'Aspyn',
              storagePath: 'Aspyn/done.mp4',
              title: 'Fly 1',
              stroke: 'Butterfly',
              distance: '50',
              course: 'LCM',
            ),
            SwimVideo(
              id: 'video-pending',
              swimmer: 'Aspyn',
              storagePath: 'Aspyn/pending.mp4',
              title: 'Fly 2',
              stroke: 'Butterfly',
              distance: '50',
              course: 'LCM',
            ),
          ],
          analyses: [
            SwimVideoAnalysis(
              swimVideoId: 'video-done',
              swimmer: 'Aspyn',
              summary: 'Elite butterfly report',
              strengths: 'Timing looks connected',
              improvements: 'Kick on entry',
              techniqueScore: 82,
              paceScore: 80,
              overallScore: 81,
              analysisJson: {
                'engine': 'swimiq-elite-v2',
                'event': '50 Butterfly LCM',
                'top_3_priorities': ['Kick on entry'],
                'sections': {
                  'Quick pro from this video': 'Timing looks connected',
                  'Quick con from this video': 'Kick on entry',
                },
              },
            ),
          ],
        ),
        swimmer: 'Aspyn',
      );

      expect(recommendation.headline, contains('AI Coach'));
      expect(recommendation.destination, PassportHubDestination.aiCoach);
      expect(recommendation.priorities, contains('Kick on entry'));
      expect(recommendation.detail.toLowerCase(), isNot(contains('race notes')));
    });

    test('surfaces latest AI priorities when analysis exists', () {
      final recommendation = PassportAiRecommendation.build(
        data: _baseData(
          videos: [
            SwimVideo(
              id: 'video-1',
              swimmer: 'Aspyn',
              storagePath: 'Aspyn/video-1.mp4',
              title: 'District Finals',
              stroke: 'Butterfly',
              distance: '50',
              course: 'SCY',
            ),
          ],
          analyses: [
            SwimVideoAnalysis(
              swimVideoId: 'video-1',
              swimmer: 'Aspyn',
              summary: '50 Fly SCY\nnotes-driven',
              strengths: '',
              improvements: '',
              techniqueScore: 80,
              paceScore: 80,
              overallScore: 80,
              analysisJson: {
                'event': '50 Butterfly SCY',
                'top_3_priorities': [
                  'Sharpen breakout timing',
                  'Hold tempo through 35m',
                ],
                'engine': 'swimiq-v1-notes',
              },
            ),
          ],
        ),
        swimmer: 'Aspyn',
      );

      expect(recommendation.headline, contains('AI Coach'));
      expect(recommendation.detail, contains('Sharpen breakout timing'));
      expect(recommendation.destination, PassportHubDestination.aiCoach);
      expect(recommendation.priorities, isNotEmpty);
    });
  });
}
