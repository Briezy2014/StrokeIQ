import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/college_recruiting_benchmark_catalog.dart';
import 'package:swimiq/core/recruiting/meet_history_analytics.dart';
import 'package:swimiq/core/recruiting/recruiting_intelligence_engine.dart';
import 'package:swimiq/core/recruiting/recruiting_resume_builder.dart';
import 'package:swimiq/core/recruiting/recruiting_resume_pdf.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/personal_best_entry.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profile = SwimmerProfile(
    swimmerName: 'Test Swimmer',
    firstName: 'Test',
    lastName: 'Swimmer',
    graduationYear: 2028,
    team: 'COA',
    school: 'Test High',
    coachName: 'Coach Smith',
    primaryStroke: 'Butterfly',
    favoriteEvent: '100 Fly',
    athleteNotes: SwimmerProfile.composeAthleteNotes(
      gpa: '3.9',
      satScore: '1300',
      recruitingStatus: 'Junior',
      gender: 'Female',
    ),
  );

  final pbs = [
    PersonalBestEntry(
      stroke: 'Fly',
      distance: 100,
      course: 'SCY',
      timeSeconds: 60.95,
      date: DateTime(2026, 3, 1),
      eventLabel: '100 Fly',
      source: PersonalBestSource.meet,
      meetName: 'State Championships',
    ),
  ];

  final meets = [
    MeetResult(
      swimmerName: 'Test Swimmer',
      meetName: 'State Championships',
      event: '100 Fly',
      swimTime: 60.95,
      course: 'SCY',
      meetDate: DateTime(2026, 2, 15),
    ),
    MeetResult(
      swimmerName: 'Test Swimmer',
      meetName: 'Winter Invite',
      event: '100 Fly',
      swimTime: 62.10,
      course: 'SCY',
      meetDate: DateTime(2025, 12, 1),
    ),
  ];

  test('recruiting resume includes passport fields', () {
    final text = RecruitingResumeBuilder.buildText(
      profile: profile,
      displayName: 'Test',
      personalBests: pbs,
      swimIqScore: 620,
      highestCut: 'AA',
      championshipsQualified: const ['State Championships'],
    );

    expect(text, contains('Test Swimmer'.toUpperCase()));
    expect(text, contains('Junior'));
    expect(text, contains('COA'));
    expect(text, contains('3.9'));
    expect(text, contains('1300'));
    expect(text, contains('100 Fly'));
  });

  test('meet history tracks attendance and progression', () {
    final summary = MeetHistoryAnalytics.build(
      meetResults: meets,
      personalBests: pbs,
    );

    expect(summary.totalMeets, 2);
    expect(summary.totalSwims, 2);
    expect(summary.meetNames, contains('State Championships'));
    expect(summary.progressionLines, isNotEmpty);
    expect(summary.championshipHighlights.first, contains('State Championships'));
  });

  test('recruiting resume PDF generates bytes', () async {
    final bytes = await RecruitingResumePdf.buildBytes(
      profile: profile,
      displayName: 'Test',
      personalBests: pbs,
      swimIqScore: 620,
      highestCut: 'AA',
      championshipsQualified: const ['State Championships'],
    );
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('recruiting intelligence produces assistant report', () async {
    final catalog = await CollegeRecruitingBenchmarkCatalog.loadFromAssets();
    final report = RecruitingIntelligenceEngine.build(
      profile: profile,
      personalBests: pbs,
      swimIqScore: 620,
      meetCount: 2,
      videoCount: 1,
      passportComplete: true,
      benchmarkCatalog: catalog,
    );

    expect(report.recruitingLevel, isNotEmpty);
    expect(report.strengths, isNotEmpty);
    expect(report.milestones, isNotEmpty);
    expect(report.divisionFit, isNotEmpty);
    expect(report.genericReachSchools, isNotEmpty);
    expect(report.genericTargetSchools, isNotEmpty);
    expect(report.genericLikelySchools, isNotEmpty);
    expect(report.timeProjections, isNotEmpty);
    expect(report.usedNamedSchoolMatching, isTrue);
  });
}
