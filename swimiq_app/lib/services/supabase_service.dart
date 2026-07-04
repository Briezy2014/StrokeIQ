import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/goal.dart';
import '../models/meet_result.dart';
import '../models/race_log.dart';
import '../models/swimmer_profile.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

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

  Future<List<Goal>> fetchGoals(String swimmerName) async {
    final response = await _client
        .from('goals')
        .select()
        .eq('swimmer_name', swimmerName)
        .order('target_date', ascending: true);

    return (response as List)
        .map((row) => Goal.fromJson(Map<String, dynamic>.from(row)))
        .toList();
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

  Future<SwimmerProfile?> fetchProfile(String swimmerName) async {
    final response = await _client
        .from('swimmers')
        .select()
        .eq('swimmer_name', swimmerName)
        .maybeSingle();

    if (response == null) return null;
    return SwimmerProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> insertRaceLog(RaceLog log) async {
    await _client.from('race_logs').insert(log.toInsertJson());
  }

  Future<void> insertGoal(Goal goal) async {
    await _client.from('goals').insert(goal.toInsertJson());
  }

  Future<void> insertMeetResult(MeetResult result) async {
    await _client.from('meet_results').insert(result.toInsertJson());
  }

  Future<void> saveProfile(SwimmerProfile profile) async {
    if (profile.id != null) {
      await _client
          .from('swimmers')
          .update(profile.toJson())
          .eq('id', profile.id!);
    } else {
      await _client.from('swimmers').insert(profile.toJson());
    }
  }
}

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
}
