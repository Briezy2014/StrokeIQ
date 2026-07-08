import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/theme/app_theme.dart';
import 'package:swimiq/data/models/meet_result.dart';
import 'package:swimiq/data/models/race_log.dart';
import 'package:swimiq/data/models/swim_goal.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/data/models/video_models.dart';
import 'package:swimiq/providers/app_providers.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';
import 'package:swimiq/screens/athlete_passport/athlete_passport_v2_screen.dart';
import 'package:swimiq/screens/dashboard/dashboard_screen.dart';
import 'package:swimiq/screens/goals/goals_screen.dart';
import 'package:swimiq/screens/meet_results/meet_results_screen.dart';
import 'package:swimiq/screens/personal_bests/personal_bests_screen.dart';
import 'package:swimiq/screens/usa_standards/usa_standards_screen.dart';
import 'package:swimiq/screens/video_lab/video_lab_screen.dart';

import 'support/motivational_standards_test_helper.dart';
import 'support/subscription_test_helper.dart';

SwimmerData? _harnessData;
late Map<String, dynamic> _fixture;

class _HarnessSwimmerDataNotifier extends SwimmerDataNotifier {
  @override
  Future<SwimmerData?> build() async => _harnessData;
}

SwimmerData _buildHarnessData() {
  final pbTitles = (_fixture['personalBestTitles'] as List).cast<String>();
  final raceLogs = pbTitles.asMap().entries.map((entry) {
    final parts = entry.value.split(' ');
    final distance = int.parse(parts.first);
    final stroke = parts.sublist(1).join(' ');
    return RaceLog(
      swimmer: _fixture['swimmer'] as String,
      event: entry.value,
      distance: distance,
      stroke: stroke,
      course: 'SCY',
      timeSeconds: (60 + entry.key).toDouble(),
      date: DateTime(2026, 6, 1 + entry.key),
    );
  }).toList();

  final raceLogTarget = _fixture['raceLogCount'] as int;
  while (raceLogs.length < raceLogTarget) {
    raceLogs.add(
      RaceLog(
        swimmer: _fixture['swimmer'] as String,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: 72,
        date: DateTime(2026, 6, 20 + raceLogs.length),
      ),
    );
  }

  final goals = List.generate(
    _fixture['goalCount'] as int,
    (index) => SwimGoal(
      swimmerName: _fixture['swimmer'] as String,
      event: '100 Butterfly',
      goalTime: 66,
      course: 'SCY',
      targetDate: DateTime(2026, 10, 1),
    ),
  );

  final meetResults = pbTitles.asMap().entries.map((entry) {
    final parts = entry.value.split(' ');
    final distance = int.parse(parts.first);
    final stroke = parts.sublist(1).join(' ');
    return MeetResult(
      swimmerName: _fixture['swimmer'] as String,
      meetName: _fixture['nextMeet'] as String,
      event: entry.value,
      swimTime: (60 + entry.key).toDouble(),
      course: 'SCY',
      meetDate: DateTime(2026, 6, 28 - entry.key),
    );
  }).toList();

  final meetResultTarget = _fixture['meetResultCount'] as int;
  while (meetResults.length < meetResultTarget) {
    meetResults.add(
      MeetResult(
        swimmerName: _fixture['swimmer'] as String,
        meetName: _fixture['nextMeet'] as String,
        event: '200 Fly',
        swimTime: 190.13,
        course: 'LCM',
        meetDate: DateTime(2026, 6, 20 + meetResults.length),
      ),
    );
  }

  final videos = List.generate(
    _fixture['userFacingVideoCount'] as int,
    (index) => SwimVideo(
      id: 'video-$index',
      swimmer: _fixture['swimmer'] as String,
      title: (_fixture['videoTitles'] as List).elementAt(index) as String,
      stroke: 'Butterfly',
      distance: '50',
      course: 'SCY',
      storagePath: 'Aspyn/video-$index.mov',
    ),
  );

  return SwimmerData(
    raceLogs: raceLogs,
    goals: goals,
    meetResults: meetResults,
    profile: const SwimmerProfile(
      id: 4,
      swimmerName: 'Aspyn',
      preferredName: 'Aspyn',
      team: 'COA',
      coachName: 'Gunner Lehr',
      primaryStroke: null,
      secondaryStroke: null,
    ),
    videos: videos,
    videoAnalyses: const [],
    usaStandards: testMotivationalCatalog.flatStandards,
    motivationalStandards: testMotivationalCatalog,
  );
}

Widget _screenHarness(Widget screen) {
  _harnessData = _buildHarnessData();
  return ProviderScope(
    overrides: [
      activeSwimmerProvider.overrideWith((ref) => _fixture['swimmer'] as String),
      swimmerDataProvider.overrideWith(_HarnessSwimmerDataNotifier.new),
      ...subscriptionTestOverrides,
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: screen),
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadTestMotivationalCatalog();
    final raw = await File('test/fixtures/aspyn_fixture.json').readAsString();
    _fixture = jsonDecode(raw) as Map<String, dynamic>;
  });

  group('Aspyn screen UI uses shared swimmer fixture', () {
    testWidgets('Dashboard', (tester) async {
      await tester.pumpWidget(_screenHarness(const DashboardScreen()));
      await tester.pumpAndSettle();

      final data = _harnessData!;
      expect(find.textContaining('WELCOME BACK'), findsOneWidget);
      expect(find.text('${data.swimIqScore}'), findsOneWidget);
      expect(find.text('Daily Rope Climb'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('SESSIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('${data.raceLogs.length}'), findsOneWidget);
      expect(find.text('${data.personalBests.length}'), findsWidgets);
      expect(find.text('${data.goals.length}'), findsWidgets);
      expect(find.text('${data.meetResults.length}'), findsOneWidget);
      expect(find.textContaining('Passport'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Recent Activity'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Unlock the Elite wild factor'), findsNothing);
    });

    testWidgets('Athlete Passport', (tester) async {
      await tester.pumpWidget(_screenHarness(const AthletePassportV2Screen()));
      await tester.pumpAndSettle();

      expect(find.textContaining(_fixture['displayName'] as String), findsWidgets);
      expect(find.text('RECRUITING PASSPORT'), findsOneWidget);
      expect(find.text('Athlete Passport™ Command Center'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Recruiting snapshot'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Recruiting snapshot'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Athlete Status'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Athlete Status'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Athlete Details'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Athlete Details'), findsOneWidget);

      expect(find.text('Coming Soon to Athlete Passport™'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Save Athlete Passport'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Save Athlete Passport'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Dominant Hand'), findsOneWidget);
    });

    testWidgets('Video Lab', (tester) async {
      await tester.pumpWidget(_screenHarness(const VideoLabScreen()));
      await tester.pumpAndSettle();

      expect(find.text('VIDEO LAB'), findsOneWidget);
      expect(find.text('AI coaching from your race footage'), findsOneWidget);
      expect(
        find.textContaining('${_fixture['userFacingVideoCount']} videos'),
        findsOneWidget,
      );
    });

    testWidgets('Goals', (tester) async {
      await tester.pumpWidget(_screenHarness(const GoalsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('GOALS'), findsOneWidget);
      expect(
        find.textContaining('Target times for ${_fixture['displayName']}'),
        findsOneWidget,
      );
    });

    testWidgets('Personal Bests', (tester) async {
      await tester.pumpWidget(_screenHarness(const PersonalBestsScreen()));
      await tester.pumpAndSettle();

      final pbCount = _harnessData!.personalBests.length;
      expect(find.text('PERSONAL BESTS'), findsOneWidget);
      expect(
        find.textContaining('$pbCount events from meet results'),
        findsOneWidget,
      );
    });

    testWidgets('Meet Results', (tester) async {
      await tester.pumpWidget(_screenHarness(const MeetResultsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MEET RESULTS'), findsOneWidget);
      expect(
        find.textContaining('Top cut:'),
        findsOneWidget,
      );
    });

    testWidgets('USA Standards', (tester) async {
      await tester.pumpWidget(_screenHarness(const UsaStandardsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('USA STANDARDS'), findsOneWidget);
      expect(
        find.textContaining('2024-2028 USA Swimming Motivational Standards'),
        findsOneWidget,
      );
    });
  });
}
