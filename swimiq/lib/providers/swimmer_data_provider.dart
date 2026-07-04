import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/meet_result.dart';
import '../data/models/race_log.dart';
import '../data/models/swim_goal.dart';
import '../data/models/swimmer_profile.dart';
import '../data/models/usa_time_standard.dart';
import '../data/models/swim_video.dart';
import 'app_providers.dart';

class SwimmerData {
  const SwimmerData({
    required this.raceLogs,
    required this.goals,
    required this.meetResults,
    this.profile,
    this.videos = const [],
    this.videoAnalyses = const [],
    this.usaStandards = const [],
  });

  final List<RaceLog> raceLogs;
  final List<SwimGoal> goals;
  final List<MeetResult> meetResults;
  final SwimmerProfile? profile;
  final List<SwimVideo> videos;
  final List<SwimVideoAnalysis> videoAnalyses;
  final List<UsaTimeStandard> usaStandards;

  SwimVideoAnalysis? analysisForVideo(String? videoId) {
    if (videoId == null) return null;
    for (final analysis in videoAnalyses) {
      if (analysis.swimVideoId == videoId) return analysis;
    }
    return null;
  }
}

class SwimmerDataNotifier extends AsyncNotifier<SwimmerData?> {
  @override
  Future<SwimmerData?> build() async {
    final swimmer = ref.watch(activeSwimmerProvider);
    if (swimmer == null || swimmer.isEmpty) return null;
    return _load(swimmer);
  }

  Future<SwimmerData> _load(String swimmer) async {
    final repository = ref.read(swimIqRepositoryProvider);

    final raceLogs = await repository.fetchRaceLogs(swimmer);
    final goals = await repository.fetchGoals(swimmer);
    final meetResults = await repository.fetchMeetResults(swimmer);
    final profile = await repository.fetchProfile(swimmer);

    List<SwimVideo> videos = [];
    List<SwimVideoAnalysis> videoAnalyses = [];
    List<UsaTimeStandard> usaStandards = [];

    try {
      videos = await repository.fetchSwimVideos(swimmer);
    } catch (_) {}

    try {
      videoAnalyses = await repository.fetchVideoAnalyses(swimmer);
    } catch (_) {}

    try {
      usaStandards = await repository.fetchUsaStandards();
    } catch (_) {
      usaStandards = await ref.read(usaStandardsServiceProvider).loadSeedStandards();
    }

    if (usaStandards.isEmpty) {
      usaStandards = await ref.read(usaStandardsServiceProvider).loadSeedStandards();
    }

    return SwimmerData(
      raceLogs: raceLogs,
      goals: goals,
      meetResults: meetResults,
      profile: profile,
      videos: videos,
      videoAnalyses: videoAnalyses,
      usaStandards: usaStandards,
    );
  }

  Future<void> refresh() async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null || swimmer.isEmpty) {
      state = const AsyncData(null);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(swimmer));
  }

  Future<String?> addRaceLog(RaceLog log) async {
    try {
      await ref.read(swimIqRepositoryProvider).insertRaceLog(log);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> addGoal(SwimGoal goal) async {
    try {
      await ref.read(swimIqRepositoryProvider).insertGoal(goal);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> addMeetResult(MeetResult result) async {
    try {
      await ref.read(swimIqRepositoryProvider).insertMeetResult(result);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> saveProfile(SwimmerProfile profile) async {
    try {
      await ref.read(swimIqRepositoryProvider).saveProfile(profile);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> uploadVideo({
    required String fileName,
    required List<int> bytes,
    String? title,
    String? stroke,
    String? distance,
    String? course,
    String? notes,
  }) async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return 'No swimmer selected.';

    try {
      await ref.read(videoStorageServiceProvider).uploadSwimVideo(
            swimmer: swimmer,
            fileName: fileName,
            bytes: Uint8List.fromList(bytes),
            title: title,
            stroke: stroke,
            distance: distance,
            course: course,
            notes: notes,
          );
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> analyzeVideo(SwimVideo video) async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return 'No swimmer selected.';

    final current = state.value;
    if (current == null) return 'No swimmer data loaded.';

    try {
      final analysis = ref.read(aiSwimAnalysisServiceProvider).analyze(
            video: video,
            raceLogs: current.raceLogs,
            goals: current.goals,
            profile: current.profile,
            standards: current.usaStandards,
          );

      await ref.read(swimIqRepositoryProvider).insertVideoAnalysis(analysis);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> importUsaStandards() async {
    try {
      await ref.read(usaStandardsServiceProvider).importSeedToSupabase();
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }
}

final swimmerDataProvider =
    AsyncNotifierProvider<SwimmerDataNotifier, SwimmerData?>(
  SwimmerDataNotifier.new,
);
