import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/meet_result.dart';
import '../data/models/race_log.dart';
import '../data/models/swim_goal.dart';
import '../data/models/swimmer_profile.dart';
import 'app_providers.dart';

class SwimmerData {
  const SwimmerData({
    required this.raceLogs,
    required this.goals,
    required this.meetResults,
    this.profile,
  });

  final List<RaceLog> raceLogs;
  final List<SwimGoal> goals;
  final List<MeetResult> meetResults;
  final SwimmerProfile? profile;

  SwimmerData copyWith({
    List<RaceLog>? raceLogs,
    List<SwimGoal>? goals,
    List<MeetResult>? meetResults,
    SwimmerProfile? profile,
    bool clearProfile = false,
  }) {
    return SwimmerData(
      raceLogs: raceLogs ?? this.raceLogs,
      goals: goals ?? this.goals,
      meetResults: meetResults ?? this.meetResults,
      profile: clearProfile ? null : (profile ?? this.profile),
    );
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
    final results = await Future.wait([
      repository.fetchRaceLogs(swimmer),
      repository.fetchGoals(swimmer),
      repository.fetchMeetResults(swimmer),
      repository.fetchProfile(swimmer),
    ]);

    return SwimmerData(
      raceLogs: results[0] as List<RaceLog>,
      goals: results[1] as List<SwimGoal>,
      meetResults: results[2] as List<MeetResult>,
      profile: results[3] as SwimmerProfile?,
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
}

final swimmerDataProvider =
    AsyncNotifierProvider<SwimmerDataNotifier, SwimmerData?>(
  SwimmerDataNotifier.new,
);
