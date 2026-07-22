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
              eventsLine: '50 Butterfly SCY\n100 Butterfly SCY\n200 IM SCY',
            ),
          ],
          motivationalStandards: testMotivationalCatalog,
        ),
        swimmer: 'Aspyn',
      );

      expect(plan.syncedToSchedule, isTrue);
      expect(plan.meetTitle, 'District Champs');
      expect(plan.meetEvents.length, greaterThanOrEqualTo(3));
      expect(plan.meetEvents, contains('50 Butterfly SCY'));
      expect(plan.meetEvents, contains('100 Butterfly SCY'));
      expect(plan.timeline.length, greaterThanOrEqualTo(4));
      expect(plan.warmUpPhases.length, 5);
      expect(plan.middayChecklist.length, greaterThanOrEqualTo(5));
      expect(plan.warmUpPlan, isNotEmpty);
      expect(plan.warmUpPlan.any((line) => line.contains('Dryland')), isTrue);
      expect(plan.warmUpPlan.any((line) => line.contains('400 easy')), isFalse);
      expect(plan.nutritionPlan.length, 4);
      expect(plan.nutritionPlan.first.mealLabel, contains('Breakfast'));
      final breakfast = plan.nutritionPlan.first;
      expect(breakfast.suggestions.any((s) => s.toLowerCase().contains('oatmeal')), isTrue);
      expect(breakfast.suggestions.any((s) => s.toLowerCase().contains('kodiak')), isTrue);
      expect(breakfast.suggestions.any((s) => s.toLowerCase().contains('peanut butter')), isTrue);
      final middayFuel = plan.nutritionPlan
          .firstWhere((block) => block.mealLabel.contains('Midday'));
      expect(middayFuel.suggestions.any((s) => s.toLowerCase().contains('honey')), isTrue);
      expect(middayFuel.suggestions.any((s) => s.toLowerCase().contains('banana')), isTrue);
      expect(middayFuel.suggestions.any((s) => s.toLowerCase().contains('oatmeal')), isTrue);
      expect(
        middayFuel.suggestions.any((s) => s.toLowerCase().contains('gumm')),
        isTrue,
      );
      expect(plan.focusEvent, contains('Butterfly'));
      expect(plan.engineLabel, contains('SwimIQ AI'));
    });

    test('can retarget plan to a selected meet event', () {
      final plan = RaceIntelligenceService.build(
        data: SwimmerData(
          raceLogs: const [],
          goals: const [],
          meetResults: const [],
          schedules: [
            SwimScheduleEntry(
              swimmerName: 'Aspyn',
              scheduleType: SwimScheduleEntry.typeMeet,
              title: 'Invite',
              scheduleDate: DateTime.now().add(const Duration(days: 2)),
              eventsLine: '50 Free, 100 Butterfly, 200 IM',
            ),
          ],
          motivationalStandards: testMotivationalCatalog,
        ),
        swimmer: 'Aspyn',
        selectedFocusEvent: '200 IM',
      );

      expect(plan.focusEvent, '200 IM');
      expect(plan.meetEvents, contains('50 Free'));
      expect(plan.meetEvents, contains('100 Butterfly'));
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
      expect(plan.syncedToSchedule, isFalse);
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
