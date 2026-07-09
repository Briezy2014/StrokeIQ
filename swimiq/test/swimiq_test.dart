import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/ai_swim_analysis_service.dart';
import 'package:swimiq/core/services/video_analysis_presenter.dart';
import 'package:swimiq/core/utils/motivational_cut.dart';
import 'package:swimiq/core/utils/passport_metrics.dart';
import 'package:swimiq/core/utils/swimiq_standards_profile.dart';
import 'package:swimiq/core/utils/swim_analytics.dart';
import 'package:swimiq/core/utils/swimiq_age_group.dart';
import 'package:swimiq/core/utils/swim_time.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';
import 'package:swimiq/data/models/video_models.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

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

    test('parseStoredTime handles colon strings from Supabase', () {
      expect(SwimTime.parseStoredTime('1:12.00'), 72.0);
      expect(SwimTime.parseStoredTime('32.50'), 32.5);
      expect(SwimTime.parseStoredTime(72), 72.0);
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

    test('calculates seconds to goal', () {
      final goal = SwimGoal(
        swimmerName: 'Aspyn',
        event: '100 Freestyle',
        goalTime: 50,
        course: 'SCY',
        targetDate: DateTime(2026, 6, 1),
      );

      final toGoal = SwimAnalytics.secondsToGoal(
        goal: goal,
        raceLogs: logs,
      );

      expect(toGoal, 5);
    });

    test('detects achieved goal', () {
      final goal = SwimGoal(
        swimmerName: 'Aspyn',
        event: '100 Freestyle',
        goalTime: 60,
        course: 'SCY',
        targetDate: DateTime(2026, 6, 1),
      );

      final toGoal = SwimAnalytics.secondsToGoal(
        goal: goal,
        raceLogs: logs,
      );

      expect(toGoal, isNotNull);
      expect(toGoal!, lessThanOrEqualTo(0));
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
    test('builds parent-friendly V1 report for 50 Butterfly LCM', () {
      const video = SwimVideo(
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/video.mov',
        title: 'Denison 50 Fly',
        stroke: 'Butterfly',
        distance: '50',
        course: 'LCM',
        notes:
            'Reaction time 0.71 off the block. Breakout at 11m after 6 dolphin kicks. '
            'Breathing every stroke on the second 25. Stroke count 17 per length. '
            'Tempo rushed in the last 15 meters. Finish with full extension.',
      );

      final analysis = AiSwimAnalysisService().analyze(
        video: video,
        raceLogs: const [],
        goals: const [],
      );

      expect(analysis.analysisJson?['event'], '50 Butterfly LCM');
      expect(analysis.disclaimer, contains('Gemini and MediaPipe'));
      expect(analysis.summary, isNot(contains('Overall readiness score')));
      expect(analysis.summary, isNot(contains('upload review')));
      expect(analysis.summary, isNot(contains('auto-measured')));

      final sections = analysis.coachingSections;
      expect(sections.keys, isNot(contains('Quick Summary')));
      expect(sections.keys, contains('Quick pro from this video'));
      expect(sections.keys, contains('Quick con from this video'));
      expect(sections.keys, contains('Goal for your next race'));
      expect(sections.keys, contains('Top 3 priorities for your next race'));
      expect(sections.keys, contains(
        'Dryland focus (strength · mobility · stability)',
      ));
      expect(sections.keys, contains('Estimated time savings'));
      expect(sections.keys, contains('Coach notes for next race'));
      expect(sections.keys, isNot(contains('What the video suggests')));
      expect(
        sections.keys,
        isNot(contains('What cannot be confirmed yet without frame-by-frame AI')),
      );

      expect(sections['Quick pro from this video'], contains('0.71'));
      expect(sections['Quick con from this video'], isNotEmpty);
      expect(sections['Goal for your next race'], isNotEmpty);
      expect(
        sections['Dryland focus (strength · mobility · stability)'],
        contains('dolphin kick on the floor'),
      );
      expect(
        sections['Top 3 priorities for your next race'],
        isNot(contains('next practice')),
      );

      expect(analysis.topPriorities.length, lessThanOrEqualTo(3));
      expect(analysis.topPriorities, isNotEmpty);
      expect(analysis.techniqueScore, greaterThan(0));
      expect(analysis.paceScore, greaterThan(0));
      expect(analysis.overallScore, greaterThan(0));
      expect(
        analysis.techniqueScore == analysis.paceScore &&
            analysis.paceScore == analysis.overallScore,
        isFalse,
        reason: 'fallback scores should differ by category',
      );
      expect(sections['Estimated time savings'], contains('Combined if you nail these'));
      expect(sections['Estimated time savings'], isNot(contains('Add detailed upload notes')));
      expect(sections['Coach notes for next race'], contains('race plan'));
      expect(sections['Coach notes for next race'], isNot(contains('Event:')));
      expect(sections['Coach notes for next race'], isNot(contains('PB reference')));
    });

    test('presenter hides legacy sections and renames practice priorities', () {
      const legacy = SwimVideoAnalysis(
        swimmer: 'Aspyn',
        summary: '50 Butterfly LCM\nOld disclaimer',
        strengths: 'legacy',
        improvements: 'legacy',
        techniqueScore: 80,
        paceScore: 78,
        overallScore: 79,
        analysisJson: {
          'disclaimer':
              'V1 report from upload notes and video metadata only — not automatic video measurement.',
          'sections': {
            'Quick Summary': 'This is a 50 Butterfly LCM upload review',
            'What the video suggests': 'Start phase is flagged',
            'What cannot be confirmed yet without frame-by-frame AI':
                'Exact reaction time',
            'Specific drills': '4 x 25 holding stroke count',
            'Top 3 priorities for the next practice': '• Practice finishes',
            'Quick pro from this video': '• Solid breakout timing',
            'Quick con from this video': '• Head lift on breath',
          },
        },
      );

      final visible = VideoAnalysisPresenter.visibleSections(legacy);
      expect(visible.keys, isNot(contains('Quick Summary')));
      expect(visible.keys, isNot(contains('What the video suggests')));
      expect(
        visible.keys,
        isNot(contains('What cannot be confirmed yet without frame-by-frame AI')),
      );
      expect(visible.keys, isNot(contains('Specific drills')));
      expect(visible.keys, contains('Top 3 priorities for your next race'));
      expect(VideoAnalysisPresenter.friendlyDisclaimer(legacy), isNull);
    });

    test('detects legacy rules-engine analyses', () {
      const legacy = SwimVideoAnalysis(
        swimmer: 'Aspyn',
        summary: 'Overall readiness score 85/100',
        strengths: 'Consistent training history with 20 logged sessions.',
        improvements: 'Film side angles',
        techniqueScore: 85,
        paceScore: 85,
        overallScore: 85,
        analysisJson: {'engine': 'swimiq-v1-rules'},
      );
      expect(legacy.isLegacyRulesEngine, isTrue);
      expect(legacy.isNotesDriven, isFalse);
    });

    test('current V1 notes analyses are not treated as legacy', () {
      const modern = SwimVideoAnalysis(
        swimVideoId: 'video-1',
        swimmer: 'Aspyn',
        summary: '50 Butterfly LCM\n• Solid breakout\n• Head lift on breath',
        strengths: 'legacy',
        improvements: 'legacy',
        techniqueScore: 80,
        paceScore: 78,
        overallScore: 79,
        analysisJson: {
          'engine': 'swimiq-v1-notes',
          'sections': {
            'Quick pro from this video': '• Solid breakout timing',
            'Quick con from this video': '• Head lift on breath',
            'Top 3 priorities for your next race': '• Practice finishes',
          },
        },
      );

      expect(modern.isLegacyRulesEngine, isFalse);
      expect(modern.isNotesDriven, isTrue);

      final data = SwimmerData(
        raceLogs: const [],
        goals: const [],
        meetResults: const [],
        videos: const [
          SwimVideo(
            id: 'video-1',
            swimmer: 'Aspyn',
            storagePath: 'Aspyn/real.mov',
            title: 'Denison 50 Fly',
          ),
        ],
        videoAnalyses: [modern],
        usaStandards: testMotivationalCatalog.flatStandards,
        schedules: const [],
        motivationalStandards: testMotivationalCatalog,
      );

      expect(data.analysisForVideo('video-1'), same(modern));
    });

    test('modern sections without engine are not treated as legacy', () {
      const fromSupabase = SwimVideoAnalysis(
        swimVideoId: 'video-2',
        swimmer: 'Aspyn',
        summary: '50 Butterfly LCM',
        strengths: 'Strong breakout',
        improvements: 'Head position',
        techniqueScore: 82,
        paceScore: 80,
        overallScore: 81,
        analysisJson: {
          'sections': {
            'Quick pro from this video': 'Strong breakout timing',
            'Quick con from this video': 'Head lifts on breath',
          },
        },
      );

      expect(fromSupabase.isLegacyRulesEngine, isFalse);
    });

    test('analysisForVideo returns newest non-legacy analysis', () {
      final legacy = SwimVideoAnalysis(
        id: 'legacy-1',
        swimVideoId: 'video-3',
        swimmer: 'Aspyn',
        summary: 'Overall readiness score 72/100',
        strengths: 'legacy',
        improvements: 'legacy',
        techniqueScore: 72,
        paceScore: 72,
        overallScore: 72,
        createdAt: DateTime(2025, 1, 1),
        analysisJson: {'engine': 'swimiq-v1-rules'},
      );
      final modern = SwimVideoAnalysis(
        id: 'modern-1',
        swimVideoId: 'video-3',
        swimmer: 'Aspyn',
        summary: '50 Butterfly LCM',
        strengths: 'Strong breakout',
        improvements: 'Head position',
        techniqueScore: 82,
        paceScore: 80,
        overallScore: 81,
        createdAt: DateTime(2026, 7, 1),
        analysisJson: {
          'engine': 'swimiq-v2-gemini',
          'sections': {
            'Quick pro from this video': 'Strong breakout timing',
            'Quick con from this video': 'Head lifts on breath',
          },
        },
      );

      final data = SwimmerData(
        raceLogs: const [],
        goals: const [],
        meetResults: const [],
        videos: const [
          SwimVideo(
            id: 'video-3',
            swimmer: 'Aspyn',
            storagePath: 'Aspyn/real.mov',
            title: 'Denison 50 Fly',
          ),
        ],
        videoAnalyses: [legacy, modern],
        usaStandards: testMotivationalCatalog.flatStandards,
        schedules: const [],
        motivationalStandards: testMotivationalCatalog,
      );

      expect(data.analysisForVideo('video-3'), same(modern));
    });

    test('parseAnalysisJson accepts json string payloads', () {
      final parsed = SwimVideoAnalysis.fromJson({
        'id': 'analysis-1',
        'swim_video_id': 'video-4',
        'swimmer': 'Aspyn',
        'summary': '50 Butterfly LCM',
        'strengths': 'Strong breakout',
        'improvements': 'Head position',
        'technique_score': 82,
        'pace_score': 80,
        'overall_score': 81,
        'analysis_json':
            '{"engine":"swimiq-v2-gemini","sections":{"Quick pro from this video":"Strong breakout"}}',
      });

      expect(parsed.isLegacyRulesEngine, isFalse);
      expect(
        parsed.coachingSections['Quick pro from this video'],
        'Strong breakout',
      );
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
        notes: 'stroke count test',
      );

      expect(visible.isUserFacing, isTrue);
      expect(hidden.isUserFacing, isFalse);
    });
  });

  group('SwimIqAgeGroup', () {
    test('uses graduation year when birthday is missing', () {
      expect(
        SwimIqAgeGroup.fromProfile(
          const SwimmerProfile(
            swimmerName: 'Aspyn',
            graduationYear: 2028,
          ),
        ),
        '15-16',
      );
    });
  });

  group('PassportMetrics', () {
    test('does not guess cuts when birthday and gender are missing', () {
      final snapshot = PassportMetrics.build(
        swimmerName: 'Aspyn',
        profile: const SwimmerProfile(
          swimmerName: 'Aspyn',
          preferredName: 'Aspyn',
          birthday: null,
          graduationYear: 2028,
          athleteNotes: 'Gender: Girls',
        ),
        raceLogs: const [],
        goals: const [],
        meetResults: [
          MeetResult(
            swimmerName: 'Aspyn',
            meetName: 'Test Meet',
            event: '100 Butterfly',
            swimTime: 72.0,
            course: 'SCY',
            meetDate: DateTime(2026, 6, 1),
          ),
        ],
        videos: const [],
        videoAnalyses: const [],
        motivationalStandards: testMotivationalCatalog,
      );

      expect(snapshot.highestCut, SwimIqStandardsProfile.setupMessageShort);
      expect(
        snapshot.usaStandardsSummary,
        SwimIqStandardsProfile.setupMessage,
      );
      expect(snapshot.usaStandardsSummary, isNot(contains('AAAA')));
    });

    test('uses profile age group and gender when profile is complete', () {
      final snapshot = PassportMetrics.build(
        swimmerName: 'Aspyn',
        profile: SwimmerProfile(
          swimmerName: 'Aspyn',
          preferredName: 'Aspyn',
          birthday: DateTime(2014, 6, 1),
          athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
        ),
        raceLogs: const [],
        goals: const [],
        meetResults: [
          MeetResult(
            swimmerName: 'Aspyn',
            meetName: 'Test Meet',
            event: '100 Butterfly',
            swimTime: 72.0,
            course: 'SCY',
            meetDate: DateTime(2026, 6, 1),
          ),
        ],
        videos: const [],
        videoAnalyses: const [],
        motivationalStandards: testMotivationalCatalog,
      );

      expect(snapshot.highestCut, isNot('AAAA'));
      expect(snapshot.highestCut, isNot(SwimIqStandardsProfile.setupMessageShort));
      expect(snapshot.usaStandardsSummary, contains('Age group: 11-12'));
      expect(snapshot.usaStandardsSummary, contains('Gender: Girls'));
    });

    test('MotivationalCut returns setup message when profile incomplete', () {
      final label = MotivationalCut.labelForSwim(
        catalog: testMotivationalCatalog,
        profile: const SwimmerProfile(swimmerName: 'Aspyn'),
        stroke: 'Butterfly',
        distance: 100,
        course: 'SCY',
        timeSeconds: 72.0,
      );

      expect(label, SwimIqStandardsProfile.setupMessageShort);
    });

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
        meetResults: [
          MeetResult(
            swimmerName: 'Aspyn',
            meetName: 'Denison Invite',
            event: '50 Butterfly',
            swimTime: 32.5,
            course: 'LCM',
            meetDate: DateTime(2026, 6, 1),
          ),
        ],
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
        motivationalStandards: testMotivationalCatalog,
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
