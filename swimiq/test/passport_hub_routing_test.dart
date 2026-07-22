import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/passport_ai_recommendation.dart';
import 'package:swimiq/core/services/swim_dna_service.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

SwimmerData _baseData() {
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
      favoriteEvent: '100 Fly SCY',
    ),
    motivationalStandards: testMotivationalCatalog,
  );
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('SwimDNA profile uses passport strokes and readiness', () {
    final profile = SwimDnaService.build(data: _baseData(), swimmer: 'Aspyn');

    expect(profile.headline, contains('SwimDNA'));
    expect(profile.traits.any((trait) => trait.label == 'Primary stroke'), isTrue);
    expect(profile.traits.firstWhere((t) => t.label == 'Primary stroke').value,
        'Butterfly');
    expect(profile.strengths, isNotEmpty);
    expect(profile.growthEdges, isNotEmpty);
  });

  test('AI Coach recommendation routes to AI Coach when analysis exists', () {
    final data = _baseData().copyWith(
      videos: const [],
      videoAnalyses: const [],
    );
    final recommendation = PassportAiRecommendation.build(
      data: data,
      swimmer: 'Aspyn',
    );

    expect(recommendation.destination, PassportHubDestination.videoLab);
  });
}
