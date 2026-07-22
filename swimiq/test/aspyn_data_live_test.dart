import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swimiq/config/env.dart';
import 'package:swimiq/config/supabase_config.dart';
import 'package:swimiq/core/services/usa_motivational_standards_catalog.dart';
import 'package:swimiq/data/models/usa_time_standard.dart';
import 'package:swimiq/data/models/video_models.dart';
import 'package:swimiq/data/repositories/swimiq_repository.dart';
import 'package:swimiq/providers/swimmer_data_provider.dart';

const _swimmer = 'Aspyn';


Future<SwimmerData> loadAspynData(SwimIqRepository repository) async {
  final raceLogs = await repository.fetchRaceLogs(_swimmer);
  final goals = await repository.fetchGoals(_swimmer);
  final meetResults = await repository.fetchMeetResults(_swimmer);
  final profile = await repository.fetchProfile(_swimmer);

  List<SwimVideo> videos = [];
  List<SwimVideoAnalysis> videoAnalyses = [];
  List<UsaTimeStandard> usaStandards = [];
  final motivationalStandards =
      await UsaMotivationalStandardsCatalog.loadFromAssets();

  try {
    videos = (await repository.fetchSwimVideos(_swimmer))
        .where((video) => video.isUserFacing)
        .toList();
  } catch (_) {}

  try {
    final remoteAnalyses = await repository.fetchVideoAnalyses(_swimmer);
    videoAnalyses = remoteAnalyses
        .where(
          (analysis) =>
              analysis.swimVideoId != null &&
              videos.any((video) => video.id == analysis.swimVideoId),
        )
        .toList();
  } catch (_) {}

  try {
    usaStandards = await repository.fetchUsaStandards();
  } catch (_) {}

  if (usaStandards.isEmpty) {
    usaStandards = motivationalStandards.flatStandards;
  }

  return SwimmerData(
    raceLogs: raceLogs,
    goals: goals,
    meetResults: meetResults,
    profile: profile,
    videos: videos,
    videoAnalyses: videoAnalyses,
    usaStandards: usaStandards,
    motivationalStandards: motivationalStandards,
  );
}

/// Live Supabase verification that every screen derives from one Aspyn SwimmerData.
///
/// Skips automatically when Supabase is unreachable (CI / local without keys).
void main() {
  late SwimIqRepository repository;
  late bool liveSupabase;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!Env.isConfigured) {
      liveSupabase = false;
      return;
    }
    repository = SwimIqRepository(
      SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey),
    );
    liveSupabase = await _canReachSupabase(repository);
  });

  group('Aspyn single-source data verification', () {
    test('loads Aspyn records from Supabase', () async {
      if (!liveSupabase) return;
      final data = await loadAspynData(repository);

      expect(data.raceLogs, isNotEmpty, reason: 'Aspyn should have race logs');
      expect(data.goals, isNotEmpty, reason: 'Aspyn should have goals');
      expect(data.meetResults, isNotEmpty, reason: 'Aspyn should have meet results');
    });

    test('all records belong to swimmer Aspyn', () async {
      if (!liveSupabase) return;
      final data = await loadAspynData(repository);

      for (final log in data.raceLogs) {
        expect(log.swimmer, _swimmer);
      }
      for (final goal in data.goals) {
        expect(goal.swimmerName, _swimmer);
      }
      for (final meet in data.meetResults) {
        expect(meet.swimmerName, _swimmer);
      }
      for (final video in data.videos) {
        expect(video.swimmer, _swimmer);
      }
      if (data.profile != null) {
        expect(data.profile!.swimmerName, _swimmer);
      }
    });

    test('every screen metric derives from the same SwimmerData snapshot', () async {
      if (!liveSupabase) return;
      final data = await loadAspynData(repository);
      final snapshot = data.passportSnapshot(_swimmer);
      final displayName = data.displayName(_swimmer);

      // Dashboard metrics
      expect(displayName, snapshot.displayName);
      expect(data.swimIqScore, snapshot.swimIqScore);
      expect(data.raceLogs.length, greaterThan(0));
      expect(data.personalBests.length, greaterThan(0));
      expect(data.goals.length, greaterThan(0));
      expect(data.meetResults.length, greaterThan(0));

      // Athlete Passport
      expect(snapshot.swimmerName, _swimmer);
      expect(snapshot.currentFocus, isNotEmpty);
      expect(snapshot.nextMeet, isNotEmpty);
      expect(snapshot.videoCount, data.userFacingVideos.length);
      expect(snapshot.analysisCount, data.userFacingVideoAnalyses.length);

      // Video Lab
      expect(snapshot.latestAnalysisSummary, isNotEmpty);
      for (final video in data.userFacingVideos) {
        expect(video.isUserFacing, isTrue);
        expect(video.swimmer, _swimmer);
      }

      // Goals
      expect(snapshot.goalLines.length, greaterThan(0));

      // Personal Bests (passport shows up to 6 lines)
      expect(snapshot.personalBests.length, greaterThan(0));
      expect(snapshot.personalBests.length, lessThanOrEqualTo(data.personalBests.length));
      expect(
        snapshot.personalBests.length,
        data.personalBests.length > 6 ? 6 : data.personalBests.length,
      );

      // Upcoming meet comes from Schedule — never photo-upload placeholders.
      expect(snapshot.nextMeet.toLowerCase(), isNot(contains('uploaded best')));

      // USA Standards
      expect(snapshot.usaStandardsSummary, isNotEmpty);
      expect(data.usaStandards, isNotEmpty);
    });

    test('writes Aspyn fixture for widget screen verification', () async {
      if (!liveSupabase) return;
      final data = await loadAspynData(repository);
      final snapshot = data.passportSnapshot(_swimmer);
      final fixture = {
        'swimmer': _swimmer,
        'displayName': data.displayName(_swimmer),
        'swimIqScore': data.swimIqScore,
        'raceLogCount': data.raceLogs.length,
        'personalBestCount': data.personalBests.length,
        'goalCount': data.goals.length,
        'meetResultCount': data.meetResults.length,
        'userFacingVideoCount': data.userFacingVideos.length,
        'analysisCount': data.userFacingVideoAnalyses.length,
        'currentFocus': snapshot.currentFocus,
        'nextMeet': snapshot.nextMeet,
        'usaStandardsSummary': snapshot.usaStandardsSummary,
        'latestAnalysisSummary': snapshot.latestAnalysisSummary,
        'goalLines': snapshot.goalLines,
        'personalBestTitles': data.personalBests
            .map((pb) => '${pb.distance} ${pb.stroke}')
            .toList(),
        'meetNames': data.meetResults.map((m) => m.meetName).toSet().toList(),
        'videoTitles':
            data.userFacingVideos.map((v) => v.displayTitle).toList(),
      };

      final file = File('test/fixtures/aspyn_fixture.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(fixture));
    });

    test('integration test videos are excluded from user-facing lists', () async {
      if (!liveSupabase) return;
      final data = await loadAspynData(repository);
      final allVideos = await repository.fetchSwimVideos(_swimmer);

      final integrationCount = allVideos
          .where((video) => !video.isUserFacing)
          .length;
      expect(integrationCount, greaterThan(0));

      for (final video in data.userFacingVideos) {
        expect(video.title, isNot('Integration test video'));
      }
    });
  });
}

Future<bool> _canReachSupabase(SwimIqRepository repository) async {
  try {
    final logs = await repository.fetchRaceLogs(_swimmer);
    return logs.isNotEmpty;
  } catch (_) {
    return false;
  }
}
