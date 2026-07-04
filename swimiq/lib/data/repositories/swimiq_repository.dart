import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_parsers.dart';
import '../models/meet_result.dart';
import '../models/race_log.dart';
import '../models/swim_goal.dart';
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
    final response = await _client
        .from('swim_video_analyses')
        .select()
        .or('swimmer.eq.$swimmer,swimmer_name.eq.$swimmer')
        .order('created_at', ascending: false);

    return supabaseRowsToMaps(response)
        .map(SwimVideoAnalysis.fromJson)
        .toList();
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

  Future<int> upsertUsaStandards(List<UsaTimeStandard> standards) async {
    if (standards.isEmpty) return 0;
    await _client.from('usa_time_standards').upsert(
          standards.map((s) => s.toInsertJson()).toList(),
          onConflict: 'age_group,gender,stroke,distance,course,standard_level',
        );
    return standards.length;
  }
}
