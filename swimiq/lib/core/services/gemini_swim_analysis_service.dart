import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_pose_metrics.dart';
import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../utils/youth_friendly_analysis.dart';
import '../../data/models/swimmer_profile.dart';

typedef VideoAnalysisPoll = Future<SwimVideoAnalysis?> Function();

/// Calls the Supabase Edge Function that sends swim video to Google Gemini.
class GeminiSwimAnalysisService {
  GeminiSwimAnalysisService(this._client);

  static const functionName = 'analyze-swim-video';
  static const currentFunctionVersion = '2026-gemini-stream-v6';
  static const analysisTimeout = Duration(minutes: 3);
  static const pollInterval = Duration(seconds: 3);
  static const pollMaxWait = Duration(minutes: 3);

  final SupabaseClient _client;

  static bool isSupportedFunctionVersion(String? version) {
    if (version == null || version.isEmpty) return false;
    return version.startsWith('2026-gemini');
  }

  /// Ping the deployed edge function — confirms server update + API key.
  Future<VideoAnalysisServerHealth> checkServerHealth() async {
    final response = await _client.functions.invoke(
      functionName,
      body: {'health_check': true},
    );

    final data = response.data;
    if (response.status == 200 && data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['ok'] == true) {
        return VideoAnalysisServerHealth.fromJson(map);
      }
      if (map['error'] != null) {
        return VideoAnalysisServerHealth.failed(map['error'].toString());
      }
    }

    if (response.status == 400 &&
        data is Map &&
        data['error']?.toString().contains('storage_path') == true) {
      return VideoAnalysisServerHealth.failed(
        'Old video server still running — run KARA-GEMINI-FIX-NOW.bat to deploy '
        'auto-model picking (you only need GEMINI_API_KEY, not GEMINI_MODEL).',
      );
    }

    if (response.status == 404) {
      return VideoAnalysisServerHealth.failed(
        'analyze-swim-video function not deployed — run KARA-GEMINI-FIX-NOW.bat.',
      );
    }

    if (response.status == 503 &&
        data is Map &&
        data['error']?.toString().toLowerCase().contains('gemini_api_key') == true) {
      return VideoAnalysisServerHealth.failed(
        'GEMINI_API_KEY missing in Supabase → Edge Functions → Secrets.',
      );
    }

    return VideoAnalysisServerHealth.failed(
      'Server check failed (${response.status}). Deploy analyze-swim-video.',
    );
  }

  Future<SwimVideoAnalysis> analyzeVideo({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
    SwimPoseMetrics? poseMetrics,
    VideoAnalysisPoll? pollForResult,
  }) async {
    final response = await _client.functions
        .invoke(
          functionName,
          body: buildRequestBody(
            video: video,
            raceLogs: raceLogs,
            goals: goals,
            profile: profile,
            poseMetrics: poseMetrics,
          ),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw GeminiAnalysisException(
              'Could not reach the video analysis server. Check your connection and try again.',
            );
          },
        );

    final data = response.data;
    if (response.status == 202 ||
        (data is Map && data['status']?.toString() == 'processing')) {
      if (pollForResult == null) {
        throw GeminiAnalysisException(
          'Video server is processing your clip — refresh the Video tab in a minute.',
        );
      }
      return _pollForVideoAnalysis(pollForResult);
    }

    if (response.status != 200) {
      if (data is Map && data['error'] != null) {
        throw GeminiAnalysisException(data['error'].toString());
      }
      if (response.status == 504) {
        throw GeminiAnalysisException(
          'Video server timed out (504). Run KARA-GEMINI-FIX-NOW.bat to deploy stream-v6, '
          'then try again with a clip under 60 seconds.',
        );
      }
      if (response.status == 546) {
        throw GeminiAnalysisException(
          'WORKER_RESOURCE_LIMIT (546): video server out of date or clip too large. '
          'Run KARA-GEMINI-FIX-NOW.bat, then use clips under 25 MB.',
        );
      }
      throw GeminiAnalysisException(
        'Video analysis service error (${response.status}).',
      );
    }

    if (data is Map && data['error'] != null) {
      throw GeminiAnalysisException(data['error'].toString());
    }

    if (data is! Map) {
      throw GeminiAnalysisException(
        'Unexpected response from $functionName.',
      );
    }

    return YouthFriendlyAnalysis.sanitizeAnalysis(
      parseAnalysisResponse(Map<String, dynamic>.from(data)),
    );
  }

  Future<SwimVideoAnalysis> _pollForVideoAnalysis(
    VideoAnalysisPoll pollForResult,
  ) async {
    final deadline = DateTime.now().add(pollMaxWait);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);
      final result = await pollForResult();
      if (result == null) continue;

      if (result.isGeminiEngine) {
        return YouthFriendlyAnalysis.sanitizeAnalysis(result);
      }

      final reason = result.analysisJson?['gemini_fallback_reason']?.toString();
      if (reason != null && reason.trim().isNotEmpty) {
        throw GeminiAnalysisException(reason.trim());
      }
    }

    throw GeminiAnalysisException(
      'Video analysis is taking longer than expected. Wait 1 minute, refresh the Video tab, '
      'or try a shorter clip (under 60 seconds / 25 MB).',
    );
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
    final analysisJson = SwimVideoAnalysis.parseAnalysisJson(json['analysis_json']);

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

class VideoAnalysisServerHealth {
  const VideoAnalysisServerHealth({
    required this.ok,
    required this.message,
    this.functionVersion,
    this.maxVideoMb,
    this.geminiModel,
    this.availableModels,
    this.modelProbeOk,
  });

  factory VideoAnalysisServerHealth.fromJson(Map<String, dynamic> json) {
    final models = json['available_models'];
    final modelList = models is List
        ? models.map((m) => m.toString()).join(', ')
        : json['gemini_model']?.toString();
    final probeOk = json['model_probe_ok'] == true;
    final probeError = json['model_probe_error']?.toString();
    final version = json['function_version']?.toString();
    final isCurrentVersion =
        GeminiSwimAnalysisService.isSupportedFunctionVersion(version);
    return VideoAnalysisServerHealth(
      ok: json['ok'] == true,
      message: _healthMessage(
        ok: json['ok'] == true,
        isCurrentVersion: isCurrentVersion,
        version: version,
        geminiModel: json['gemini_model']?.toString(),
        maxVideoMb: json['max_video_mb']?.toString(),
        probeError: probeError,
      ),
      functionVersion: version,
      maxVideoMb: int.tryParse(json['max_video_mb']?.toString() ?? ''),
      geminiModel: json['gemini_model']?.toString(),
      availableModels: modelList,
      modelProbeOk: probeOk,
    );
  }

  static String _healthMessage({
    required bool ok,
    required bool isCurrentVersion,
    String? version,
    String? geminiModel,
    String? maxVideoMb,
    String? probeError,
  }) {
    if (!isCurrentVersion) {
      return 'Video server may need an update (version ${version ?? "unknown"}). '
          'Run KARA-GEMINI-FIX-NOW.bat if Analyze fails.';
    }
    if (ok) {
      return 'Video server ready (version $version, model $geminiModel, '
          'max $maxVideoMb MB). Tap Analyze on your clip.';
    }
    return probeError ??
        'Gemini model probe failed. Create a NEW key at aistudio.google.com/apikey, '
        'update GEMINI_API_KEY in Supabase, then run KARA-GEMINI-FIX-NOW.bat.';
  }

  factory VideoAnalysisServerHealth.failed(String message) {
    return VideoAnalysisServerHealth(ok: false, message: message);
  }

  final bool ok;
  final String message;
  final String? functionVersion;
  final int? maxVideoMb;
  final String? geminiModel;
  final String? availableModels;
  final bool? modelProbeOk;
}
