import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../data/models/swimmer_profile.dart';

/// Calls the Supabase Edge Function that sends swim video to Google Gemini.
class GeminiSwimAnalysisService {
  GeminiSwimAnalysisService(this._client);

  static const functionName = 'analyze-swim-video';

  final SupabaseClient _client;

  Future<SwimVideoAnalysis> analyzeVideo({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: buildRequestBody(
        video: video,
        raceLogs: raceLogs,
        goals: goals,
        profile: profile,
      ),
    );

    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw GeminiAnalysisException(data['error'].toString());
    }

    if (data is! Map) {
      throw GeminiAnalysisException(
        'Unexpected response from $functionName.',
      );
    }

    return parseAnalysisResponse(Map<String, dynamic>.from(data));
  }

  static Map<String, dynamic> buildRequestBody({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
  }) {
    final recentSessions = raceLogs.take(5).map((log) {
      return '${log.distance} ${log.stroke} ${log.course} '
          '${SwimTime.fromSeconds(log.timeSeconds)}';
    }).toList();

    final personalBests = <String>[];
    final seen = <String>{};
    for (final log in raceLogs) {
      final key = '${log.distance}-${log.stroke}-${log.course}';
      if (!seen.add(key)) continue;
      personalBests.add(
        '${log.distance} ${log.stroke} ${log.course} '
        '${SwimTime.fromSeconds(log.timeSeconds)}',
      );
      if (personalBests.length >= 6) break;
    }

    final goalLines = goals.take(5).map((goal) {
      return '${goal.event} ${SwimTime.fromSeconds(goal.goalTime)} '
          'by ${goal.targetDate.toIso8601String().split('T').first}';
    }).toList();

    return {
      'video_id': video.id,
      'storage_path': video.storagePath,
      'swimmer': video.swimmer,
      'event_label': video.eventLabel,
      'title': video.displayTitle,
      'notes': video.notes,
      'coach_context': {
        'display_name': profile?.preferredName ?? profile?.swimmerName,
        'team': profile?.team,
        'personal_bests': personalBests,
        'goals': goalLines,
        'recent_sessions': recentSessions,
      },
    };
  }

  static SwimVideoAnalysis parseAnalysisResponse(Map<String, dynamic> json) {
    final analysisJson = json['analysis_json'] is Map
        ? Map<String, dynamic>.from(json['analysis_json'] as Map)
        : null;

    return SwimVideoAnalysis(
      swimVideoId: json['swim_video_id']?.toString(),
      swimmer: json['swimmer']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      strengths: json['strengths']?.toString() ?? '',
      improvements: json['improvements']?.toString() ?? '',
      techniqueScore: _parseScore(json['technique_score']),
      paceScore: _parseScore(json['pace_score']),
      overallScore: _parseScore(json['overall_score']),
      analysisJson: analysisJson,
    );
  }

  static int _parseScore(Object? value) {
    if (value is int) return value.clamp(0, 100);
    final parsed = int.tryParse(value?.toString() ?? '');
    return (parsed ?? 70).clamp(0, 100);
  }
}

class GeminiAnalysisException implements Exception {
  GeminiAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}
