import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/recruiting_intelligence_engine.dart';
import 'package:swimiq/core/services/college_recruiting_benchmark_catalog.dart';
import 'package:swimiq/data/models/personal_best_entry.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestMotivationalCatalog();
  });

  test('matches named Central US schools for 100 Fly SCY', () async {
    final catalog = await CollegeRecruitingBenchmarkCatalog.loadFromAssets();
    final profile = SwimmerProfile(
      swimmerName: 'Aspyn',
      birthday: DateTime(2010, 6, 1),
      athleteNotes: SwimmerProfile.composeAthleteNotes(
        gender: 'Female',
        collegeInterests: 'Central US',
      ),
    );
    final pbs = [
      PersonalBestEntry(
        stroke: 'Butterfly',
        distance: 100,
        course: 'SCY',
        timeSeconds: 58.5,
        date: DateTime(2026, 7, 6),
        eventLabel: '100 Butterfly',
        source: PersonalBestSource.meet,
        meetName: 'Summer Invite',
      ),
    ];

    final matches = catalog.matchSchools(
      personalBests: pbs,
      profile: profile,
    );

    expect(matches, isNotEmpty);
    expect(
      matches.any((match) => match.region.contains('Central')),
      isTrue,
    );
    expect(
      matches.any(
        (match) =>
            match.school.contains('Miami') ||
            match.school.contains('Cincinnati') ||
            match.school.contains('Ohio'),
      ),
      isTrue,
    );
    // Unrealistic power-conference reaches should be filtered out.
    expect(
      matches.any(
        (match) =>
            match.school.contains('Michigan') &&
            match.tier == CollegeMatchTier.reach &&
            match.gapToTargetSeconds > 10,
      ),
      isFalse,
    );

    final report = RecruitingIntelligenceEngine.build(
      profile: profile,
      personalBests: pbs,
      swimIqScore: 550,
      meetCount: 1,
      videoCount: 0,
      passportComplete: true,
      benchmarkCatalog: catalog,
      standardsCatalog: testMotivationalCatalog,
    );

    expect(report.usedNamedSchoolMatching, isTrue);
    expect(report.milestones, isNotEmpty);
    expect(
      report.milestones.any((line) => line.toLowerCase().contains('regional')),
      isFalse,
    );
    expect(
      report.milestones.any(
        (line) =>
            line.contains('Earn ') ||
            line.contains('AAAA') ||
            line.contains('AA') ||
            line.contains('AAA') ||
            line.contains('BB') ||
            line.contains('drop'),
      ),
      isTrue,
    );
    expect(report.timeProjections.first.targetSchoolName, isNotNull);
    expect(report.divisionFit, isNotEmpty);
  });

  test('does not treat athlete email as coach contact fallback in résumé text',
      () {
    final profile = SwimmerProfile(
      swimmerName: 'Aspyn',
      athleteNotes: SwimmerProfile.composeAthleteNotes(
        gender: 'Female',
        athleteEmail: 'athlete@example.com',
        recruitingEmail: 'athlete@example.com',
        coachEmail: null,
      ),
    );

    expect(profile.coachEmail, isNull);
    expect(profile.recruitingEmail, 'athlete@example.com');
  });
}
