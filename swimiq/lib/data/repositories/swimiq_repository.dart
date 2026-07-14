import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_parsers.dart';
import '../../core/utils/supabase_table_errors.dart';
import '../models/meet_result.dart';
import '../models/race_log.dart';
import '../models/swim_goal.dart';
import '../models/swim_schedule_entry.dart';
import '../models/swimmer_profile.dart';
import '../models/usa_time_standard.dart';
import '../models/video_models.dart';

class SwimIqRepository {
  SwimIqRepository(this._client);

  final SupabaseClient _client;

  Future<List<RaceLog>> fetchRaceLogs(String swimmer) async {
    final response = await _client
        .from('race_logs')
        .select()
        .eq('swimmer', swimmer)
        .order('date', ascending: false);

    return (response as List)
        .map((row) => RaceLog.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> insertRaceLog(RaceLog log) async {
    await _client.from('race_logs').insert(log.toInsertJson());
  }

  Future<void> updateRaceLog(RaceLog log) async {
    if (log.id == null) {
      throw ArgumentError('Race log id is required for update.');
    }
    await _client.from('race_logs').update(log.toInsertJson()).eq('id', log.id!);
  }

  Future<void> deleteRaceLog(int id) async {
    await _client.from('race_logs').delete().eq('id', id);
  }

  Future<List<SwimGoal>> fetchGoals(String swimmerName) async {
    final response = await _client
        .from('goals')
        .select()
        .eq('swimmer_name', swimmerName)
        .order('target_date', ascending: true);

    return (response as List)
        .map((row) => SwimGoal.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> insertGoal(SwimGoal goal) async {
    await _client.from('goals').insert(goal.toInsertJson());
  }

  Future<void> updateGoal(SwimGoal goal) async {
    if (goal.id == null) {
      throw ArgumentError('Goal id is required for update.');
    }
    await _client.from('goals').update(goal.toInsertJson()).eq('id', goal.id!);
  }

  Future<void> deleteGoal(int id) async {
    await _client.from('goals').delete().eq('id', id);
  }

  Future<List<MeetResult>> fetchMeetResults(String swimmerName) async {
    final response = await _client
        .from('meet_results')
        .select()
        .eq('swimmer_name', swimmerName)
        .order('meet_date', ascending: false);

    return (response as List)
        .map((row) => MeetResult.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> insertMeetResult(MeetResult result) async {
    await _client.from('meet_results').insert(result.toInsertJson());
  }

  Future<void> updateMeetResult(MeetResult result) async {
    if (result.id == null) {
      throw ArgumentError('Meet result id is required for update.');
    }
    await _client
        .from('meet_results')
        .update(result.toInsertJson())
        .eq('id', result.id!);
  }

  Future<void> deleteMeetResult(int id) async {
    await _client.from('meet_results').delete().eq('id', id);
  }

  Future<List<SwimScheduleEntry>> fetchSchedules(String swimmerName) async {
    final response = await _client
        .from('swim_schedules')
        .select()
        .eq('swimmer_name', swimmerName)
        .order('schedule_date', ascending: true)
        .order('start_time', ascending: true);

    return (response as List)
        .map((row) => SwimScheduleEntry.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> insertSchedule(SwimScheduleEntry entry) async {
    await _client.from('swim_schedules').insert(entry.toInsertJson());
  }

  Future<void> updateSchedule(SwimScheduleEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError('Schedule id is required for update.');
    }
    await _client
        .from('swim_schedules')
        .update(entry.toInsertJson())
        .eq('id', entry.id!);
  }

  Future<void> deleteSchedule(int id) async {
    await _client.from('swim_schedules').delete().eq('id', id);
  }

  Future<SwimmerProfile?> fetchProfile(String swimmerName) async {
    final response = await _client
        .from('swimmers')
        .select()
        .eq('swimmer_name', swimmerName)
        .maybeSingle();

    if (response == null) return null;
    return SwimmerProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<SwimmerProfile> saveProfile(SwimmerProfile profile) async {
    final data = Map<String, dynamic>.from(profile.toJson())
      ..removeWhere((key, value) => value == null);
    if (profile.id != null) {
      await _client.from('swimmers').update(data).eq('id', profile.id!);
      return profile;
    }

    final existing = await fetchProfile(profile.swimmerName);
    if (existing?.id != null) {
      await _client.from('swimmers').update(data).eq('id', existing!.id!);
      return profile.copyWith(id: existing.id);
    }

    final response = await _client
        .from('swimmers')
        .insert(data)
        .select()
        .single();
    return SwimmerProfile.fromJson(Map<String, dynamic>.from(response));
  }

  /// Creates a minimal swimmer profile if one does not exist yet.
  Future<SwimmerProfile> ensureSwimmerProfile({
    required String swimmerName,
    String? preferredName,
    String? email,
  }) async {
    final existing = await fetchProfile(swimmerName);
    if (existing != null) return existing;

    final profile = SwimmerProfile(
      swimmerName: swimmerName,
      preferredName: preferredName ?? swimmerName,
      athleteNotes: email != null ? 'Account: $email' : null,
    );
    return saveProfile(profile);
  }

  Future<List<SwimVideo>> fetchSwimVideos(String swimmer) async {
    final response = await _client
        .from('swim_videos')
        .select()
        .or('swimmer.eq.$swimmer,swimmer_name.eq.$swimmer')
        .order('created_at', ascending: false);

    return supabaseRowsToMaps(response)
        .map(SwimVideo.fromJson)
        .toList();
  }

  Future<SwimVideo> insertSwimVideo(SwimVideo video) async {
    final response = await _client
        .from('swim_videos')
        .insert(video.toInsertJson())
        .select()
        .single();

    final row = supabaseRowToMap(response);
    try {
      return SwimVideo.fromJson(row);
    } catch (_) {
      return video.copyWith(
        id: parseUuid(row['id']),
        swimmer: swimmerFromJson(row).isEmpty ? video.swimmer : swimmerFromJson(row),
        videoUrl: parseOptionalText(row['video_url']) ?? video.videoUrl,
      );
    }
  }

  Future<List<SwimVideoAnalysis>> fetchVideoAnalyses(String swimmer) async {
    try {
      final response = await _client
          .from('swim_video_analyses')
          .select()
          .or('swimmer.eq.$swimmer,swimmer_name.eq.$swimmer')
          .order('created_at', ascending: false);

      return supabaseRowsToMaps(response)
          .map(SwimVideoAnalysis.fromJson)
          .toList();
    } catch (error) {
      if (SupabaseTableErrors.isMissingTable(
        error,
        tableName: 'swim_video_analyses',
      )) {
        return [];
      }
      rethrow;
    }
  }

  Future<SwimVideoAnalysis?> insertVideoAnalysisOptional(
    SwimVideoAnalysis analysis,
  ) async {
    try {
      return await insertVideoAnalysis(analysis);
    } catch (_) {
      return null;
    }
  }

  Future<SwimVideoAnalysis> insertVideoAnalysis(SwimVideoAnalysis analysis) async {
    final response = await _client
        .from('swim_video_analyses')
        .insert(analysis.toInsertJson())
        .select()
        .single();
    return SwimVideoAnalysis.fromSupabaseRow(response);
  }

  Future<void> deleteSwimVideo(String videoId) async {
    try {
      await _client
          .from('swim_video_analyses')
          .delete()
          .eq('swim_video_id', videoId);
    } catch (error) {
      if (!SupabaseTableErrors.isMissingTable(
        error,
        tableName: 'swim_video_analyses',
      )) {
        rethrow;
      }
    }

    final response = await _client
        .from('swim_videos')
        .delete()
        .eq('id', videoId)
        .select();

    final rows = supabaseRowsToMaps(response);
    if (rows.isEmpty) {
      throw StateError(
        'Video was not removed from the database. Sign in again and retry.',
      );
    }
  }

  Future<List<UsaTimeStandard>> fetchUsaStandards() async {
    final response = await _client
        .from('usa_time_standards')
        .select()
        .order('age_group')
        .order('stroke')
        .order('distance');

    return (response as List)
        .map((row) => UsaTimeStandard.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

}
