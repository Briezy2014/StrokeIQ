import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/coaching/race_opportunity_meter.dart';
import 'package:swimiq/data/models/video_engine_v2/analysis_results.dart';

void main() {
  test('Opportunity Meter maps breathing issue and allocates potential drop', () {
    final meter = RaceOpportunityMeterBuilder.fromReport(
      report: const AnalysisReport(
        summary: 'Aspyn, on this 50 butterfly: keep your rhythm.',
        strengths: [
          'Your stroke timing looks connected.',
        ],
        priorityImprovements: [
          PriorityImprovement(
            title:
                'Your hips drop when you lift your head to breathe. Press your chest.',
            drills: [
              'Dryland: 3 x 20s hollow-body holds.',
              'Swim: 6× 25 fly breathe every other stroke.',
            ],
          ),
        ],
        raceRecommendations: [
          'Race cue: kick on entry, press the chest, breathe late and low.',
          'First 15m: tight underwater dolphins.',
          'many age-group 50 fly swimmers drop about 0.3-0.8 seconds - that\'s your potential.',
        ],
      ),
      stroke: 'Butterfly',
      distanceM: 50,
    );

    expect(meter.hasPotential, isTrue);
    expect(meter.potentialLowSec, 0.3);
    expect(meter.potentialHighSec, 0.8);
    expect(meter.raceIq, inInclusiveRange(40, 99));
    expect(meter.segments.map((s) => s.id), containsAll(['breathing', 'tempo', 'finish']));
    expect(meter.segments.map((s) => s.id), isNot(contains('turns')));

    final breathing = meter.segments.firstWhere((s) => s.id == 'breathing');
    expect(breathing.signal, OpportunitySignal.opportunity);
    expect(breathing.opportunityLowSec, isNotNull);
    expect(breathing.opportunityHighSec, isNotNull);
    expect(breathing.opportunityLabel, contains('~'));
    expect(breathing.drylandDrills, isNotEmpty);
    expect(breathing.swimDrills, isNotEmpty);

    final reaction = meter.segments.firstWhere((s) => s.id == 'reaction');
    expect(reaction.signal, OpportunitySignal.lockedIn);
    expect(reaction.opportunityLabel, 'Locked in');
  });

  test('100s include turns segment', () {
    final meter = RaceOpportunityMeterBuilder.fromReport(
      report: const AnalysisReport(
        summary: 'Freestyle 100',
        priorityImprovements: [
          PriorityImprovement(title: 'Your flip turn is slow off the wall.'),
        ],
        raceRecommendations: const [],
      ),
      stroke: 'Freestyle',
      distanceM: 100,
    );

    expect(meter.segments.map((s) => s.id), contains('turns'));
    final turns = meter.segments.firstWhere((s) => s.id == 'turns');
    expect(turns.signal, OpportunitySignal.opportunity);
  });
}
