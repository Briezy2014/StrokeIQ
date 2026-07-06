import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/services/meet_schedule_scan_service.dart';
import '../core/utils/swimmer_profile_notes.dart';
import '../data/models/meet_schedule_queue_item.dart';
import '../data/models/scheduled_meet.dart';
import '../data/models/swimmer_profile.dart';
import 'app_providers.dart';
import 'swimmer_data_provider.dart';

final meetScheduleScanServiceProvider = Provider<MeetScheduleScanService>(
  (ref) => MeetScheduleScanService(ref.watch(supabaseClientProvider)),
);

class MeetScheduleUploadState {
  const MeetScheduleUploadState({this.isProcessing = false});

  final bool isProcessing;
}

class MeetScheduleUploadNotifier extends Notifier<MeetScheduleUploadState> {
  final _uuid = const Uuid();

  @override
  MeetScheduleUploadState build() => const MeetScheduleUploadState();

  Future<String?> uploadSchedulePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null || swimmer.isEmpty) {
      return 'No swimmer selected.';
    }

    final current = ref.read(swimmerDataProvider).value;
    final profile = current?.profile;
    if (profile == null) {
      return 'Save your Passport profile first.';
    }

    final queueId = _uuid.v4();
    var queue = [
      MeetScheduleQueueItem(
        id: queueId,
        fileName: fileName,
        status: MeetQueueStatus.processing,
        uploadedAt: DateTime.now(),
      ),
      ...profile.meetQueue,
    ];

    state = const MeetScheduleUploadState(isProcessing: true);
    await _saveProfile(profile, profile.scheduledMeets, queue);

    try {
      final parsed = await ref.read(meetScheduleScanServiceProvider).parseScheduleImage(
            bytes: bytes,
            fileName: fileName,
            teamName: profile.team,
          );

      if (parsed.isEmpty) {
        queue = _updateQueueItem(
          queue,
          queueId,
          MeetScheduleQueueItem(
            id: queueId,
            fileName: fileName,
            status: MeetQueueStatus.error,
            uploadedAt: DateTime.now(),
            error: 'No upcoming meets found in this photo.',
          ),
        );
        await _saveProfile(profile, profile.scheduledMeets, queue);
        return 'No upcoming meets found. Try a clearer photo of the schedule.';
      }

      final merged = _mergeMeets(profile.scheduledMeets, parsed);
      queue = _updateQueueItem(
        queue,
        queueId,
        MeetScheduleQueueItem(
          id: queueId,
          fileName: fileName,
          status: MeetQueueStatus.done,
          uploadedAt: DateTime.now(),
          meetCount: parsed.length,
        ),
      );
      await _saveProfile(profile, merged, queue);
      return null;
    } on MeetScheduleScanException catch (error) {
      queue = _updateQueueItem(
        queue,
        queueId,
        MeetScheduleQueueItem(
          id: queueId,
          fileName: fileName,
          status: MeetQueueStatus.error,
          uploadedAt: DateTime.now(),
          error: error.message,
        ),
      );
      await _saveProfile(profile, profile.scheduledMeets, queue);
      return error.message;
    } catch (error) {
      queue = _updateQueueItem(
        queue,
        queueId,
        MeetScheduleQueueItem(
          id: queueId,
          fileName: fileName,
          status: MeetQueueStatus.error,
          uploadedAt: DateTime.now(),
          error: error.toString(),
        ),
      );
      await _saveProfile(profile, profile.scheduledMeets, queue);
      return error.toString();
    } finally {
      state = const MeetScheduleUploadState(isProcessing: false);
    }
  }

  Future<String?> setAttending({
    required String meetExternalId,
    required bool attending,
  }) async {
    final current = ref.read(swimmerDataProvider).value;
    final profile = current?.profile;
    if (profile == null) {
      return 'Save your Passport profile first.';
    }

    final ids = {...profile.attendingMeetIds};
    if (attending) {
      ids.add(meetExternalId);
    } else {
      ids.remove(meetExternalId);
    }

    final updated = profile.copyWith(
      athleteNotes: SwimmerProfileNotes.merge(
        existing: profile,
        attendingMeetIds: ids.toList()..sort(),
      ),
    );

    return ref.read(swimmerDataProvider.notifier).saveProfile(updated);
  }

  Future<String?> clearQueue() async {
    final profile = ref.read(swimmerDataProvider).value?.profile;
    if (profile == null) return null;
    return _saveProfile(profile, profile.scheduledMeets, const []);
  }

  List<ScheduledMeet> _mergeMeets(
    List<ScheduledMeet> existing,
    List<ScheduledMeet> incoming,
  ) {
    final byId = {for (final m in existing) m.externalId: m};
    for (final meet in incoming) {
      byId[meet.externalId] = meet;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return merged;
  }

  List<MeetScheduleQueueItem> _updateQueueItem(
    List<MeetScheduleQueueItem> queue,
    String id,
    MeetScheduleQueueItem updated,
  ) {
    return [
      updated,
      ...queue.where((item) => item.id != id),
    ];
  }

  Future<String?> _saveProfile(
    SwimmerProfile profile,
    List<ScheduledMeet> meets,
    List<MeetScheduleQueueItem> queue,
  ) {
    final updated = profile.copyWith(
      athleteNotes: SwimmerProfileNotes.merge(
        existing: profile,
        scheduledMeets: meets,
        meetQueue: queue.take(20).toList(),
      ),
    );
    return ref.read(swimmerDataProvider.notifier).saveProfile(updated);
  }
}

final meetScheduleUploadProvider =
    NotifierProvider<MeetScheduleUploadNotifier, MeetScheduleUploadState>(
  MeetScheduleUploadNotifier.new,
);

final scheduledMeetsProvider = Provider<List<ScheduledMeet>>((ref) {
  final profile = ref.watch(swimmerDataProvider).value?.profile;
  if (profile == null) return const [];

  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);

  return profile.scheduledMeets
      .where((m) => !m.startDate.isBefore(startOfToday))
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
});

final meetQueueProvider = Provider<List<MeetScheduleQueueItem>>((ref) {
  return ref.watch(swimmerDataProvider).value?.profile?.meetQueue ?? const [];
});

/// Meets this swimmer marked as attending.
final attendingMeetsProvider = Provider<List<ScheduledMeet>>((ref) {
  final meets = ref.watch(scheduledMeetsProvider);
  final profile = ref.watch(swimmerDataProvider).value?.profile;
  if (profile == null) return const [];

  final ids = profile.attendingMeetIds.toSet();
  if (ids.isEmpty) return const [];

  return meets.where((m) => ids.contains(m.externalId)).toList();
});
