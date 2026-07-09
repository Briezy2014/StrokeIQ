import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/race_intelligence_service.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swim_schedule_entry.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  group('RaceIntelligenceService', () {
    test('builds meet-day plan with nutrition and checklist', () {
      final plan = RaceIntelligenceService.build(
        data: SwimmerData(
          raceLogs: const [],
          goals: [
            SwimGoal(
              swimmerName: 'Aspyn',
              event: '100 Butterfly',
              goalTime: 66,
              course: 'SCY',
              targetDate: DateTime(2026, 10, 1),
            ),
          ],
          meetResults: const [],
          profile: SwimmerProfile(
            swimmerName: 'Aspyn',
            preferredName: 'Aspyn',
            birthday: DateTime(2014, 1, 1),
            athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
          ),
          schedules: [
            SwimScheduleEntry(
              swimmerName: 'Aspyn',
              scheduleType: SwimScheduleEntry.typeMeet,
              title: 'District Champs',
              scheduleDate: DateTime.now().add(const Duration(days: 3)),
              startTime: '10:30 AM',
              eventsLine: '50 Butterfly SCY',
            ),
          ],
          motivationalStandards: testMotivationalCatalog,
        ),
        swimmer: 'Aspyn',
      );

      expect(plan.middayChecklist.length, greaterThanOrEqualTo(5));
      expect(plan.warmUpPlan, isNotEmpty);
      expect(plan.warmUpPlan.any((line) => line.contains('Dryland')), isTrue);
      expect(plan.warmUpPlan.any((line) => line.contains('400 easy')), isFalse);
      expect(plan.nutritionPlan.length, 4);
      expect(plan.nutritionPlan.first.mealLabel, contains('Breakfast'));
      expect(plan.focusEvent, contains('Butterfly'));
      expect(plan.engineLabel, contains('SwimIQ AI'));
    });

    test('uses goals when no schedule events are saved', () {
      final plan = RaceIntelligenceService.build(
        data: SwimmerData(
          raceLogs: const [],
          goals: [
            SwimGoal(
              swimmerName: 'Aspyn',
              event: '200 IM',
              goalTime: 130,
              course: 'SCY',
              targetDate: DateTime(2026, 10, 1),
            ),
          ],
          meetResults: const [],
          motivationalStandards: testMotivationalCatalog,
        ),
        swimmer: 'Aspyn',
      );

      expect(plan.focusEvent, '200 IM');
      expect(plan.nutritionPlan.any((block) => block.mealLabel.contains('Midday')), isTrue);
    });
  });

  group('SwimScheduleEntry', () {
    test('round-trips schedule types', () {
      final entry = SwimScheduleEntry(
        swimmerName: 'Aspyn',
        scheduleType: SwimScheduleEntry.typePractice,
        title: 'Saturday AM',
        scheduleDate: DateTime(2026, 7, 12),
        startTime: '7:00 AM',
      );

      expect(entry.isPractice, isTrue);
      expect(entry.typeLabel, 'Practice');
      expect(entry.toInsertJson()['schedule_type'], 'practice');
    });
  });
}
