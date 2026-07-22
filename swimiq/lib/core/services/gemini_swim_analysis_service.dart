import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_pose_metrics.dart';
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
    SwimPoseMetrics? poseMetrics,
  }) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: buildRequestBody(
          video: video,
          raceLogs: raceLogs,
          goals: goals,
          profile: profile,
          poseMetrics: poseMetrics,
        ),
      );

      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw GeminiAnalysisException(
          _friendlyMessage(data['error'].toString()),
        );
      }

      if (data is! Map) {
        throw GeminiAnalysisException(
          'Unexpected response from AI analysis. '
          'Confirm the analyze-swim-video Edge Function is deployed.',
        );
      }

      return parseAnalysisResponse(Map<String, dynamic>.from(data));
    } on GeminiAnalysisException {
      rethrow;
    } on FunctionException catch (error) {
      throw GeminiAnalysisException(_friendlyMessage(_functionExceptionText(error)));
    } catch (error) {
      throw GeminiAnalysisException(_friendlyMessage(error.toString()));
    }
  }

  static String _functionExceptionText(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    if (details != null) return details.toString();
    return error.toString();
  }

  /// Turns raw Edge/Gemini failures into a clear next step for parents.
  static String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('too large') ||
        lower.contains('413') ||
        lower.contains('payload')) {
      return 'This video file is too large for AI analysis (cloud limit is about '
          '100 MB after the server update). Trim or re-export a shorter clip, '
          'then tap Analyze again.';
    }
    if (lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('idle_timeout') ||
        lower.contains('504')) {
      return 'Analysis timed out. Use a clip under 2 minutes (ideally under 60 '
          'seconds), keep this tab open, and try again.';
    }
    if (lower.contains('gemini_api_key') ||
        lower.contains('api key') ||
        lower.contains('not configured')) {
      return 'AI analysis is not configured on the server yet '
          '(missing GEMINI_API_KEY). Email support@swimiqapp.com.';
    }
    if (lower.contains('not found') && lower.contains('function')) {
      return 'AI analysis server function is not deployed. '
          'Run DEPLOY-GEMINI-VIDEO.bat, then try Analyze again.';
    }
    if (lower.contains('resource_exhausted') ||
        lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('high demand') ||
        lower.contains('503')) {
      return 'AI coaching is busy right now. Wait one or two minutes, '
          'then tap Analyze again.';
    }
    if (lower.contains('unauthorized') || lower.contains('jwt')) {
      return 'Please sign out, sign back in, then tap Analyze again.';
    }
    return raw.trim().isEmpty
        ? 'AI analysis failed. Try again in a minute.'
        : raw.trim();
  }

  static Map<String, dynamic> buildRequestBody({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
    SwimPoseMetrics? poseMetrics,
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
      if (poseMetrics != null) 'pose_metrics': poseMetrics.toJson(),
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
