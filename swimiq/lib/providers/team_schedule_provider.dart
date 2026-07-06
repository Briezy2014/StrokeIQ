import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/team_schedule_service.dart';
import '../data/models/scheduled_meet.dart';
import '../data/models/swimmer_profile.dart';
import 'app_providers.dart';
import 'swimmer_data_provider.dart';

class TeamScheduleState {
  const TeamScheduleState({
    this.meets = const [],
    this.pdfLinks = const [],
    this.teamName,
    this.isSyncing = false,
    this.lastSyncedAt,
    this.error,
  });

  final List<ScheduledMeet> meets;
  final List<TeamSchedulePdfLink> pdfLinks;
  final String? teamName;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? error;

  TeamScheduleState copyWith({
    List<ScheduledMeet>? meets,
    List<TeamSchedulePdfLink>? pdfLinks,
    String? teamName,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    String? error,
    bool clearError = false,
  }) {
    return TeamScheduleState(
      meets: meets ?? this.meets,
      pdfLinks: pdfLinks ?? this.pdfLinks,
      teamName: teamName ?? this.teamName,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final teamScheduleServiceProvider = Provider<TeamScheduleService>(
  (ref) => TeamScheduleService(ref.watch(supabaseClientProvider)),
);

class TeamScheduleNotifier extends Notifier<TeamScheduleState> {
  @override
  TeamScheduleState build() => const TeamScheduleState();

  bool get isCoaTeam {
    final profile = ref.read(swimmerDataProvider).value?.profile;
    final team = profile?.team?.toLowerCase() ?? '';
    return team.contains('coa') ||
        team.contains('central ohio') ||
        team.contains('central ohio aquatics');
  }

  Future<String?> syncCoaSchedule() async {
    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      final result =
          await ref.read(teamScheduleServiceProvider).syncCoaSchedule();
      state = state.copyWith(
        meets: result.meets,
        pdfLinks: result.pdfLinks,
        teamName: result.teamName,
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      );
      return null;
    } on TeamScheduleException catch (error) {
      state = state.copyWith(isSyncing: false, error: error.message);
      return error.message;
    } catch (error) {
      final message = error.toString();
      state = state.copyWith(isSyncing: false, error: message);
      return message;
    }
  }

  Future<String?> setAttending({
    required String meetExternalId,
    required bool attending,
  }) async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null || swimmer.isEmpty) {
      return 'No swimmer selected.';
    }

    final current = ref.read(swimmerDataProvider).value;
    final profile = current?.profile;
    if (profile == null) {
      return 'Save the athlete passport profile first.';
    }

    final ids = {...profile.attendingMeetIds};
    if (attending) {
      ids.add(meetExternalId);
    } else {
      ids.remove(meetExternalId);
    }

    final updated = profile.copyWith(
      athleteNotes: SwimmerProfile.composeAthleteNotes(
        gender: profile.gender,
        height: profile.height,
        weight: profile.weight,
        dominantHand: profile.dominantHand,
        trainingGroup: profile.trainingGroup,
        profilePhotoUrl: profile.profilePhotoUrl,
        sleepHours: profile.sleepHours,
        sorenessLevel: profile.sorenessLevel,
        illnessNotes: profile.illnessNotes,
        attendingMeetIds: ids.toList()..sort(),
        notes: profile.notesBody,
      ),
    );

    return ref.read(swimmerDataProvider.notifier).saveProfile(updated);
  }

  List<ScheduledMeet> attendingMeetsFor(SwimmerProfile? profile) {
    if (profile == null) return const [];
    final ids = profile.attendingMeetIds.toSet();
    if (ids.isEmpty) return const [];

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return state.meets
        .where(
          (meet) =>
              ids.contains(meet.externalId) &&
              !meet.startDate.isBefore(startOfToday),
        )
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}

final teamScheduleProvider =
    NotifierProvider<TeamScheduleNotifier, TeamScheduleState>(
  TeamScheduleNotifier.new,
);

/// Meets this swimmer marked as attending (requires synced team schedule).
final attendingMeetsProvider = Provider<List<ScheduledMeet>>((ref) {
  ref.watch(teamScheduleProvider);
  final profile = ref.watch(swimmerDataProvider).value?.profile;
  return ref.read(teamScheduleProvider.notifier).attendingMeetsFor(profile);
});
