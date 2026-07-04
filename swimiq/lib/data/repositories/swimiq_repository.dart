import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meet_result.dart';
import '../models/race_log.dart';
import '../models/swim_goal.dart';
import '../models/swimmer_profile.dart';
import '../models/swim_video.dart';

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

  Future<void> saveProfile(SwimmerProfile profile) async {
    final data = profile.toJson();
    if (profile.id != null) {
      await _client.from('swimmers').update(data).eq('id', profile.id!);
    } else {
      await _client.from('swimmers').insert(data);
    }
  }

  Future<List<SwimVideo>> fetchSwimVideos(String swimmerName) async {
    final response = await _client
        .from('swim_videos')
        .select()
        .eq('swimmer_name', swimmerName)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => SwimVideo.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<SwimVideo> insertSwimVideo(SwimVideo video) async {
    final response = await _client
        .from('swim_videos')
        .insert(video.toInsertJson())
        .select()
        .single();
    return SwimVideo.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<SwimVideoAnalysis>> fetchVideoAnalyses(String swimmerName) async {
    final response = await _client
        .from('swim_video_analyses')
        .select()
        .eq('swimmer_name', swimmerName)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => SwimVideoAnalysis.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<SwimVideoAnalysis> insertVideoAnalysis(SwimVideoAnalysis analysis) async {
    final response = await _client
        .from('swim_video_analyses')
        .insert(analysis.toInsertJson())
        .select()
        .single();
    return SwimVideoAnalysis.fromJson(Map<String, dynamic>.from(response));
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
