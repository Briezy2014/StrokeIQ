import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/meet_day_service.dart';
import 'package:swimiq/core/services/recruiting_passport_service.dart';
import 'package:swimiq/core/services/season_arc_service.dart';
import 'package:swimiq/core/services/standards_gap_service.dart';
import 'package:swimiq/core/services/swim_dna_service.dart';
import 'package:swimiq/core/services/video_compare_service.dart';
import 'package:swimiq/core/services/wellness_readiness_service.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swim_video.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

SwimmerData _baseData({
  SwimmerProfile? profile,
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
    profile: profile ??
        SwimmerProfile(
          id: 4,
          swimmerName: 'Aspyn',
          preferredName: 'Aspyn',
          primaryStroke: 'Butterfly',
          birthday: DateTime(2012, 3, 1),
          athleteNotes: SwimmerProfile.composeAthleteNotes(
            gender: 'Girls',
            sleepHours: '8',
            sorenessLevel: 'Mild',
          ),
        ),
    videos: const [
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
    videoAnalyses: analyses,
    motivationalStandards: testMotivationalCatalog,
  );
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  group('SwimDnaService', () {
    test('builds fingerprint traits from logs', () {
      final brief = SwimDnaService.build(data: _baseData(), swimmer: 'Aspyn');
      expect(brief.traits, isNotEmpty);
      expect(brief.raceProfile, isNotEmpty);
    });
  });

  group('MeetDayService', () {
    test('builds checklist and lineup', () {
      final brief = MeetDayService.build(data: _baseData(), swimmer: 'Aspyn');
      expect(brief.checklist.length, greaterThan(3));
      expect(brief.raceLineup, isNotEmpty);
    });
  });

  group('RecruitingPassportService', () {
    test('builds shareable card', () {
      final brief =
          RecruitingPassportService.build(data: _baseData(), swimmer: 'Aspyn');
      expect(brief.shareableCard, contains('SwimIQ Recruiting Passport'));
      expect(brief.shareableCard, contains('Aspyn'));
    });
  });

  group('SeasonArcService', () {
    test('detects training phase', () {
      final brief = SeasonArcService.build(data: _baseData(), swimmer: 'Aspyn');
      expect(brief.currentPhase.name, isNotEmpty);
      expect(brief.milestones, isNotEmpty);
    });
  });

  group('StandardsGapService', () {
    test('reports gap when profile is ready', () {
      final brief =
          StandardsGapService.build(data: _baseData(), swimmer: 'Aspyn');
      expect(brief.headline, contains('gap'));
    });
  });

  group('VideoCompareService', () {
    test('needs two analyses for full compare', () {
      final brief = VideoCompareService.build(
        data: _baseData(
          analyses: [
            SwimVideoAnalysis(
              swimVideoId: 'video-1',
              swimmer: 'Aspyn',
              summary: 'a',
              strengths: 's',
              improvements: 'i',
              techniqueScore: 80,
              paceScore: 80,
              overallScore: 80,
              createdAt: DateTime(2026, 6, 2),
            ),
          ],
        ),
        swimmer: 'Aspyn',
      );
      expect(brief.older, isNull);
      expect(brief.newer, isNotNull);
    });
  });

  group('WellnessReadinessService', () {
    test('scores readiness from wellness fields', () {
      final brief =
          WellnessReadinessService.build(data: _baseData(), swimmer: 'Aspyn');
      expect(brief.readinessScore, greaterThan(0));
      expect(brief.factors, isNotEmpty);
    });
  });
}
