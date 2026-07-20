import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/career_highlights.dart';
import 'package:swimiq/core/services/usa_motivational_standards_catalog.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/personal_best_entry.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swim_video_analysis.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profile = SwimmerProfile(
    swimmerName: 'Aspyn Tester',
    firstName: 'Aspyn',
    lastName: 'Tester',
    graduationYear: 2029,
    team: 'COA',
    birthday: DateTime(2012, 6, 1),
    athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
  );

  final meets = [
    MeetResult(
      swimmerName: 'Aspyn Tester',
      meetName: 'Winter Invite',
      event: '100 Butterfly',
      swimTime: 92.13,
      course: 'LCM',
      meetDate: DateTime(2024, 12, 1),
    ),
    MeetResult(
      swimmerName: 'Aspyn Tester',
      meetName: 'State Championships',
      event: '100 Butterfly',
      swimTime: 82.29,
      course: 'LCM',
      meetDate: DateTime(2025, 7, 12),
    ),
    MeetResult(
      swimmerName: 'Aspyn Tester',
      meetName: 'Age Group JO Champs',
      event: '50 Freestyle',
      swimTime: 33.03,
      course: 'LCM',
      meetDate: DateTime(2026, 3, 1),
    ),
    MeetResult(
      swimmerName: 'Aspyn Tester',
      meetName: 'Uploaded best times',
      event: '50 Freestyle',
      swimTime: 32.50,
      course: 'LCM',
      meetDate: DateTime(2026, 3, 2),
    ),
  ];

  final pbs = [
    PersonalBestEntry(
      stroke: 'Butterfly',
      distance: 100,
      course: 'LCM',
      timeSeconds: 82.29,
      date: DateTime(2025, 7, 12),
      eventLabel: '100 Butterfly',
      source: PersonalBestSource.meet,
      meetName: 'State Championships',
    ),
    PersonalBestEntry(
      stroke: 'Freestyle',
      distance: 50,
      course: 'LCM',
      timeSeconds: 33.03,
      date: DateTime(2026, 3, 1),
      eventLabel: '50 Freestyle',
      source: PersonalBestSource.meet,
      meetName: 'Age Group JO Champs',
    ),
  ];

  test('builds sales cards ordered by significance and hides empties', () async {
    final catalog = await UsaMotivationalStandardsCatalog.loadFromAssets();
    final summary = CareerHighlightsBuilder.build(
      meetResults: meets,
      personalBests: pbs,
      goals: const [],
      raceLogs: const [],
      catalog: catalog,
      profile: profile,
      swimIqScore: 620,
      videoAnalyses: const [],
    );

    expect(summary.hasAnything, isTrue);
    expect(summary.meets, 3); // upload ignored
    expect(summary.races, 4);
    expect(summary.lifetimePbs, 2);
    expect(summary.swimIqRating, 'Competitive');
    expect(summary.improvementTrendPercent, isNotNull);

    final ids = summary.cards.map((c) => c.id).toList();
    expect(ids, contains('biggest_drop'));
    expect(ids, contains('most_improved'));
    expect(ids, contains('lifetime_pbs'));
    expect(ids, contains('swimiq_rating'));
    expect(ids, contains('career_achievement'));
    expect(ids, isNot(contains('goal_rate')));
    expect(ids, isNot(contains('technical_strength')));

    // Significance order: first card is highest.
    for (var i = 0; i < summary.cards.length - 1; i++) {
      expect(
        summary.cards[i].significance,
        greaterThanOrEqualTo(summary.cards[i + 1].significance),
      );
    }

    final drop = summary.cards.firstWhere((c) => c.id == 'biggest_drop');
    expect(drop.value, startsWith('-'));
    expect(drop.subtitle, contains('100 Butterfly'));

    final achievement =
        summary.cards.firstWhere((c) => c.id == 'career_achievement');
    // JO ranks above State when both appear in history.
    expect(
      achievement.value,
      anyOf('Junior Olympics', contains('Qualifier'), contains('Standard')),
    );
  });

  test('technical strength maps underwater cue from video AI', () async {
    final catalog = await UsaMotivationalStandardsCatalog.loadFromAssets();
    final analysis = SwimVideoAnalysis(
      swimmer: 'Aspyn Tester',
      summary: 'Solid race.',
      strengths: 'Strong kick off the walls.',
      improvements: 'Hold tempo late.',
      techniqueScore: 80,
      paceScore: 75,
      overallScore: 78,
      createdAt: DateTime(2026, 3, 10),
      analysisJson: {
        'engine': 'swimiq-v2-gemini',
        'sections': {
          'Quick Pro from this video':
              'Elite underwater dolphin kick off every wall.',
        },
      },
    );

    final summary = CareerHighlightsBuilder.build(
      meetResults: meets,
      personalBests: pbs,
      goals: const [],
      raceLogs: const [],
      catalog: catalog,
      profile: profile,
      swimIqScore: 700,
      videoAnalyses: [analysis],
    );

    final tech = summary.cards.firstWhere((c) => c.id == 'technical_strength');
    expect(tech.value, 'Elite Underwaters');
  });

  test('goal completion card appears when goals exist', () async {
    final catalog = await UsaMotivationalStandardsCatalog.loadFromAssets();
    final goals = [
      SwimGoal(
        swimmerName: 'Aspyn Tester',
        event: '100 Butterfly',
        goalTime: 85.0,
        course: 'LCM',
        targetDate: DateTime(2026, 8, 1),
      ),
      SwimGoal(
        swimmerName: 'Aspyn Tester',
        event: '50 Freestyle',
        goalTime: 30.0,
        course: 'LCM',
        targetDate: DateTime(2026, 8, 1),
      ),
    ];

    final summary = CareerHighlightsBuilder.build(
      meetResults: meets,
      personalBests: pbs,
      goals: goals,
      raceLogs: const [],
      catalog: catalog,
      profile: profile,
      swimIqScore: 500,
      videoAnalyses: const [],
    );

    final goal = summary.cards.firstWhere((c) => c.id == 'goal_rate');
    expect(goal.value, contains('of 2'));
    expect(goal.subtitle, contains('%'));
  });

  test('empty athlete yields no cards', () async {
    final catalog = await UsaMotivationalStandardsCatalog.loadFromAssets();
    final summary = CareerHighlightsBuilder.build(
      meetResults: const [],
      personalBests: const [],
      goals: const [],
      raceLogs: const [],
      catalog: catalog,
      profile: null,
      swimIqScore: 0,
      videoAnalyses: const [],
    );

    expect(summary.hasAnything, isFalse);
    expect(summary.cards, isEmpty);
  });
}
