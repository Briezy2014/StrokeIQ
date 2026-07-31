import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/constants/demo_account_constants.dart';
import 'package:swimiq/core/services/ai_dryland_coach_service.dart';
import 'package:swimiq/core/services/swim_dna_service.dart';
import 'package:swimiq/core/utils/swimiq_standards_profile.dart';
import 'package:swimiq/data/demo/aspyn_briez_demo_seed.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  group('Aspyn Briez coach demo seed', () {
    test('fills every major data surface for a complete profile walkthrough', () {
      final data = AspynBriezDemoSeed.build(
        motivationalStandards: testMotivationalCatalog,
        now: DateTime(2026, 7, 30),
      );

      expect(data.profile?.preferredName, 'Aspyn Briez');
      expect(data.profile?.firstName, 'Aspyn');
      expect(data.profile?.lastName, 'Briez');
      expect(data.profile?.team, 'COA');
      expect(data.profile?.coachName, 'Gunner Lehr');
      expect(data.profile?.gpa, '3.85');
      expect(data.profile?.collegeInterests, contains('Ohio'));
      expect(data.profile?.recruitingStatus, contains('Open'));
      expect(data.profile?.intendedMajor, contains('Exercise'));
      expect(data.profile?.gender, 'Female');
      expect(SwimIqStandardsProfile.isReady(data.profile), isTrue);

      expect(data.meetResults.length, greaterThanOrEqualTo(15));
      expect(data.personalBests, isNotEmpty);
      expect(data.raceLogs.length, greaterThanOrEqualTo(20));
      expect(data.goals.length, greaterThanOrEqualTo(6));
      expect(data.schedules.where((s) => s.isMeet), isNotEmpty);
      expect(data.schedules.where((s) => s.isPractice), isNotEmpty);

      expect(data.userFacingVideos.length, 5);
      expect(data.userFacingVideoAnalyses.length, 5);
      for (final video in data.userFacingVideos) {
        final analysis = data.analysisForVideo(video.id);
        expect(analysis, isNotNull, reason: video.title);
        expect(analysis!.isLegacyRulesEngine, isFalse);
        expect(analysis.coachingSections['Quick Summary'], isNotEmpty);
        expect(analysis.topPriorities, isNotEmpty);
      }

      final snapshot = data.passportSnapshot(AspynBriezDemoSeed.swimmerName);
      expect(snapshot.displayName, contains('Aspyn'));
      expect(snapshot.currentFocus.toLowerCase(), contains('butterfly'));
      expect(data.swimIqScore, greaterThan(0));

      final dna = SwimDnaService.build(
        data: data,
        swimmer: AspynBriezDemoSeed.swimmerName,
      );
      expect(dna.traits, isNotEmpty);
      expect(dna.techniquePriorities, isNotEmpty);

      final dryland = AiDrylandCoachService.build(
        data: data,
        swimmer: AspynBriezDemoSeed.swimmerName,
      );
      expect(dryland.workoutBlocks, isNotEmpty);
      expect(dryland.hasVideoTechniqueLoop, isTrue);
    });

    test('demo email and swimmer keys resolve to Aspyn Briez showcase', () {
      expect(DemoAccountConstants.isDemoEmail('demo@swimiqapp.com'), isTrue);
      expect(DemoAccountConstants.isDemoSwimmerKey('SwimIQ Demo'), isTrue);
      expect(DemoAccountConstants.isDemoSwimmerKey('Aspyn Briez'), isTrue);
      expect(AspynBriezDemoSeed.shouldUse(email: 'demo@swimiqapp.com'), isTrue);
      expect(
        AspynBriezDemoSeed.shouldUse(swimmerKey: 'SwimIQ Demo'),
        isTrue,
      );
      expect(DemoAccountConstants.athleteName, 'Aspyn Briez');
    });
  });
}
