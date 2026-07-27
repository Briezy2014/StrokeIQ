import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/cut_to_college_service.dart';
import 'package:swimiq/core/recruiting/living_passport_payload.dart';
import 'package:swimiq/core/recruiting/meet_day_brief_pdf.dart';
import 'package:swimiq/core/services/ai_dryland_coach_service.dart';
import 'package:swimiq/core/services/parent_race_pulse_service.dart';
import 'package:swimiq/core/services/race_intelligence_service.dart';
import 'package:swimiq/core/services/swim_dna_service.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/swim_schedule_entry.dart';
import 'package:swimiq/data/models/swim_video.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  SwimmerData sampleData({bool withVideo = true}) {
    final videos = withVideo
        ? [
            const SwimVideo(
              id: 'vid-1',
              swimmer: 'Aspyn',
              storagePath: 'videos/aspyn.mp4',
              title: '100 Fly finals',
              stroke: 'Butterfly',
              distance: '100',
              course: 'SCY',
            ),
          ]
        : const <SwimVideo>[];
    final analyses = withVideo
        ? [
            SwimVideoAnalysis(
              swimVideoId: 'vid-1',
              swimmer: 'Aspyn',
              summary: 'Strong race',
              strengths: 'Kick',
              improvements: 'Head position',
              techniqueScore: 80,
              paceScore: 78,
              overallScore: 79,
              createdAt: DateTime(2026, 7, 1),
              analysisJson: {
                'engine': 'swimiq-v2-gemini',
                'top_3_priorities': [
                  'Keep head neutral off the walls',
                  'Finish the last 5 meters',
                  'Tighten streamline',
                ],
                'sections': {
                  'Quick pro from this video': 'Strong kick tempo',
                  'Quick con from this video': 'Head lifts early',
                  'Top 3 priorities for your next race': 'Head, finish, streamline',
                },
              },
            ),
          ]
        : const <SwimVideoAnalysis>[];

    return SwimmerData(
      raceLogs: const [],
      goals: const [],
      meetResults: [
        MeetResult(
          swimmerName: 'Aspyn',
          meetName: 'Spring Invite',
          event: '100 Butterfly',
          swimTime: 68.2,
          course: 'SCY',
          meetDate: DateTime(2026, 3, 1),
        ),
      ],
      schedules: [
        SwimScheduleEntry(
          swimmerName: 'Aspyn',
          scheduleType: SwimScheduleEntry.typeMeet,
          title: 'Summer Invite',
          scheduleDate: DateTime.now().add(const Duration(days: 5)),
          startTime: '8:30 AM',
        ),
      ],
      profile: SwimmerProfile(
        swimmerName: 'Aspyn',
        firstName: 'Aspyn',
        lastName: 'Briez',
        preferredName: 'Aspyn',
        birthday: DateTime(2014, 6, 8),
        graduationYear: 2032,
        team: 'Central Ohio Aquatics',
        athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
      ),
      videos: videos,
      videoAnalyses: analyses,
      motivationalStandards: testMotivationalCatalog,
    );
  }

  group('LivingPassportPayload', () {
    test('encodes and decodes coach snapshot with technique priorities', () {
      final payload = LivingPassportPayload.fromData(
        data: sampleData(),
        swimmer: 'Aspyn',
      );
      expect(payload.displayName, 'Aspyn');
      expect(payload.topTimes, isNotEmpty);
      expect(payload.latestTechniquePriorities.first, contains('head'));
      expect(payload.latestClipLabel, '100 Fly finals');
      expect(payload.shareUrl(), contains('lp='));

      final roundTrip = LivingPassportPayload.tryDecode(payload.encode());
      expect(roundTrip, isNotNull);
      expect(roundTrip!.displayName, payload.displayName);
      expect(roundTrip.swimIqScore, payload.swimIqScore);
      expect(roundTrip.latestTechniquePriorities, payload.latestTechniquePriorities);
      expect(roundTrip.latestClipLabel, payload.latestClipLabel);
    });

    test('tryDecode returns null for garbage', () {
      expect(LivingPassportPayload.tryDecode('%%%'), isNull);
      expect(LivingPassportPayload.tryDecode(null), isNull);
    });
  });

  group('MeetDayBriefPdf', () {
    test('builds a PDF from Race Intelligence', () async {
      final plan = RaceIntelligenceService.build(
        data: sampleData(),
        swimmer: 'Aspyn',
      );
      final bytes = await MeetDayBriefPdf.buildBytes(
        plan: plan,
        athleteName: 'Aspyn Briez',
      );
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('CutToCollegeService', () {
    test('builds USA next-cut step from official PB', () {
      final timeline = CutToCollegeService.build(data: sampleData());
      expect(timeline.steps, isNotEmpty);
      expect(timeline.steps.first.kind, 'usa_cut');
      expect(timeline.summary, isNotEmpty);
    });
  });

  group('ParentRacePulseService', () {
    test('writes plain-English weekly pulse', () {
      final pulse = ParentRacePulseService.build(
        data: sampleData(),
        swimmer: 'Aspyn',
        now: DateTime(2026, 7, 21),
      );
      expect(pulse.headline, contains('Aspyn'));
      expect(pulse.shareBody, contains('SwimIQ'));
      expect(pulse.paragraphs.any((p) => p.contains('video coaching')), isTrue);
    });
  });

  group('Technique Passport + Dryland loop', () {
    test('SwimDNA includes technique priorities from latest AI clip', () {
      final profile = SwimDnaService.build(
        data: sampleData(),
        swimmer: 'Aspyn',
      );
      expect(profile.techniquePriorities, isNotEmpty);
      expect(
        profile.traits.any((t) => t.label == 'Technique passport'),
        isTrue,
      );
    });

    test('Dryland plan exposes video priorities and technique block', () {
      final plan = AiDrylandCoachService.build(
        data: sampleData(),
        swimmer: 'Aspyn',
      );
      expect(plan.hasVideoTechniqueLoop, isTrue);
      expect(plan.videoPriorities, isNotEmpty);
      expect(
        plan.workoutBlocks.any((b) => b.title.contains('Technique-informed')),
        isTrue,
      );
    });
  });
}
