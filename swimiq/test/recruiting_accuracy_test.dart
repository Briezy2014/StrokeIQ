import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/recruiting/cut_to_college_service.dart';
import 'package:swimiq/core/recruiting/living_passport_payload.dart';
import 'package:swimiq/core/services/college_recruiting_benchmark_catalog.dart';
import 'package:swimiq/core/utils/swim_time.dart';
import 'package:swimiq/data/demo/aspyn_briez_demo_seed.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

import 'support/motivational_standards_test_helper.dart';

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
  });

  test('Living Passport QR uses http://swimiqapp.com so coach scans work', () {
    final payload = LivingPassportPayload(
      displayName: 'Aspyn Briez',
      swimIqScore: 800,
      highestCut: 'BB',
      readiness: 'Race Ready',
      nextMeet: 'OSU Invite',
      powerIndexLine: '60 / 100',
      topTimes: const ['100 Butterfly  1:12.00'],
      latestTechniquePriorities: const ['Streamline'],
      generatedAtIso: '2026-07-31T00:00:00.000Z',
    );
    final url = payload.shareUrl(base: Uri.parse('https://swimiqapp.com/'));
    expect(url.startsWith('http://swimiqapp.com/?lp='), isTrue);
    final encoded = Uri.parse(url).queryParameters['lp'];
    final decoded = LivingPassportPayload.tryDecode(encoded);
    expect(decoded?.displayName, 'Aspyn Briez');
    expect(decoded?.topTimes.first, contains('1:12.00'));
  });

  test('Kenyon 200 Fly LCM Met uses athlete PB — 3:07 is not inside target',
      () async {
    final catalog = await CollegeRecruitingBenchmarkCatalog.loadFromAssets();
    final data = SwimmerData(
      raceLogs: const [],
      goals: const [],
      meetResults: [
        MeetResult(
          swimmerName: 'Aspyn Briez',
          meetName: 'OSU Summer Invite',
          event: '200 Butterfly',
          swimTime: SwimTime.toSeconds('3:07.00'),
          course: 'LCM',
          meetDate: DateTime(2026, 6, 29),
        ),
      ],
      profile: SwimmerProfile(
        swimmerName: 'Aspyn Briez',
        birthday: DateTime(2011, 3, 15),
        athleteNotes: SwimmerProfile.composeAthleteNotes(
          gender: 'Female',
          collegeInterests: 'Ohio',
        ),
      ),
      motivationalStandards: testMotivationalCatalog,
    );

    final timeline = CutToCollegeService.build(
      data: data,
      collegeCatalog: catalog,
    );
    final college = timeline.steps.where((s) => s.kind.startsWith('college'));
    expect(college, isNotEmpty);
    final kenyon = college.firstWhere(
      (s) => s.title.contains('Kenyon'),
      orElse: () => college.first,
    );
    expect(kenyon.detail, contains('your 3:07.00'));
    expect(kenyon.detail, contains('recruit window'));
    expect(kenyon.isMet, isFalse, reason: '3:07 is slower than Kenyon target');
    expect(kenyon.gapLabel, isNot(equals('Met')));
    expect(kenyon.gapLabel, contains('to target'));
  });

  test('Aspyn demo seed 200 Fly LCM PB is 3:07 for honest recruiting', () {
    final data = AspynBriezDemoSeed.build(
      motivationalStandards: testMotivationalCatalog,
      now: DateTime(2026, 7, 31),
    );
    final fly200 = data.personalBests.where(
      (pb) =>
          pb.stroke == 'Butterfly' &&
          pb.distance == 200 &&
          pb.course.toUpperCase() == 'LCM',
    );
    expect(fly200, isNotEmpty);
    expect(fly200.first.formattedTime, '3:07.00');

    final fly100 = data.personalBests.where(
      (pb) =>
          pb.stroke == 'Butterfly' &&
          pb.distance == 100 &&
          pb.course.toUpperCase() == 'SCY',
    );
    expect(fly100, isNotEmpty);
    expect(fly100.first.formattedTime, '1:12.00');
  });
}
