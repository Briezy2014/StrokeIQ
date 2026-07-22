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

  test('matches named Ohio schools for 200 Fly LCM', () async {
    final catalog = await CollegeRecruitingBenchmarkCatalog.loadFromAssets();
    final profile = SwimmerProfile(
      swimmerName: 'Aspyn',
      athleteNotes: SwimmerProfile.composeAthleteNotes(gender: 'Female'),
    );
    final pbs = [
      PersonalBestEntry(
        stroke: 'Butterfly',
        distance: 200,
        course: 'LCM',
        timeSeconds: 190.0,
        date: DateTime(2026, 7, 6),
        eventLabel: '200 Butterfly',
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
      matches.any((match) => match.school.contains('Wilmington')),
      isTrue,
    );

    final report = RecruitingIntelligenceEngine.build(
      profile: profile,
      personalBests: pbs,
      swimIqScore: 550,
      meetCount: 1,
      videoCount: 0,
      passportComplete: true,
      benchmarkCatalog: catalog,
    );

    expect(report.usedNamedSchoolMatching, isTrue);
    expect(
      report.targetSchools.any((line) => line.contains('Wilmington')),
      isTrue,
    );
    expect(report.timeProjections.first.targetSchoolName, isNotNull);
    expect(report.divisionFit, isNotEmpty);
    expect(report.genericReachSchools, isNotEmpty);
    expect(report.genericTargetSchools, isNotEmpty);
    expect(report.genericLikelySchools, isNotEmpty);
    expect(
      report.genericReachSchools.any((line) => line.contains('D1')),
      isTrue,
    );
    expect(
      report.genericLikelySchools.any((line) => line.contains('D2') || line.contains('NAIA')),
      isTrue,
    );
  });
}
