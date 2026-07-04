import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';
import '../models/meet_result.dart';
import '../models/race_log.dart';
import '../models/swimmer_profile.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final activeSwimmerProvider =
    NotifierProvider<ActiveSwimmerNotifier, String?>(ActiveSwimmerNotifier.new);

class ActiveSwimmerNotifier extends Notifier<String?> {
  static const _storageKey = 'active_swimmer';

  @override
  String? build() => null;

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_storageKey);
  }

  Future<void> setSwimmer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, trimmed);
  }

  Future<void> clearSwimmer() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

final dataRefreshProvider = Provider<int>((ref) => 0);

void refreshData(WidgetRef ref) {
  ref.invalidate(swimmerDataProvider);
}

final swimmerDataProvider = FutureProvider<SwimmerData>((ref) async {
  ref.watch(dataRefreshProvider);
  final swimmer = ref.watch(activeSwimmerProvider);
  if (swimmer == null || swimmer.isEmpty) {
    throw StateError('No active swimmer');
  }

  final service = ref.watch(supabaseServiceProvider);
  final results = await Future.wait([
    service.fetchRaceLogs(swimmer),
    service.fetchGoals(swimmer),
    service.fetchMeetResults(swimmer),
    service.fetchProfile(swimmer),
  ]);

  return SwimmerData(
    raceLogs: results[0] as List<RaceLog>,
    goals: results[1] as List<Goal>,
    meetResults: results[2] as List<MeetResult>,
    profile: results[3] as SwimmerProfile?,
  );
});

class SwimmerData {
  SwimmerData({
    required this.raceLogs,
    required this.goals,
    required this.meetResults,
    this.profile,
  });

  final List<RaceLog> raceLogs;
  final List<Goal> goals;
  final List<MeetResult> meetResults;
  final SwimmerProfile? profile;
}
