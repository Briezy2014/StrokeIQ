import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env.dart';
import '../../data/models/video_engine_v2/video_engine_v2_models.dart';

/// Exception with a mapped, user-facing message for Video Engine V2 API errors.
class VideoEngineV2Exception implements Exception {
  VideoEngineV2Exception(
    this.message, {
    this.errorCode,
    this.statusCode,
    this.retriable = false,
  });

  final String message;
  final String? errorCode;
  final int? statusCode;
  final bool retriable;

  @override
  String toString() => message;
}

typedef AccessTokenGetter = Future<String?> Function();

/// HTTP client for the Elote Video Engine V2 analysis API.
class VideoEngineV2Service {
  VideoEngineV2Service({
    http.Client? client,
    AccessTokenGetter? accessTokenGetter,
    String? baseUrl,
    SupabaseClient? supabase,
  })  : _client = client ?? http.Client(),
        _accessTokenGetter = accessTokenGetter ??
            (() async =>
                (supabase ?? Supabase.instance.client)
                    .auth
                    .currentSession
                    ?.accessToken),
        _baseUrlOverride = baseUrl;

  final http.Client _client;
  final AccessTokenGetter _accessTokenGetter;
  final String? _baseUrlOverride;

  String get baseUrl {
    final url = (_baseUrlOverride ?? Env.analysisApiBaseUrl).trim();
    if (url.isEmpty) {
      throw VideoEngineV2Exception(
        'Analysis API is not configured. Set ANALYSIS_API_BASE_URL.',
        errorCode: 'SERVER_UNAVAILABLE',
      );
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Unauthenticated ping of Elite `/health` (used before Confirm & Analyze).
  Future<EliteServerHealth> checkHealth() async {
    final uri = Uri.parse('$baseUrl/health');
    try {
      // No custom headers — keeps this a simple CORS request from Flutter web.
      final response = await _client.get(uri);
      if (response.statusCode != 200 || response.body.isEmpty) {
        return EliteServerHealth(
          reachable: false,
          message:
              'Elite server responded ${response.statusCode} at $baseUrl/health',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return EliteServerHealth(
          reachable: false,
          message: 'Elite /health returned an unexpected response.',
        );
      }
      final map = Map<String, dynamic>.from(decoded);
      final status = map['status']?.toString() ?? 'unknown';
      final ffmpeg = map['ffmpeg_available'] == true;
      final ffprobe = map['ffprobe_available'] == true;
      // Require the new health field. Missing = stale Elite server still running.
      final storageConfigured = map['storage_download_configured'] == true;
      final version = map['engine_version']?.toString();
      final ok = status == 'ok' || status == 'degraded';
      final missingMedia = !ffmpeg || !ffprobe;
      final staleServer = map['storage_download_configured'] == null;
      String message;
      if (!ok) {
        message = 'Elite server health failed at $baseUrl';
      } else if (missingMedia) {
        message =
            'Elite server is up, but FFmpeg is missing. Restart START-ELITE-ANALYSIS-SERVER.bat after installing FFmpeg.';
      } else if (staleServer) {
        message =
            'Elite server is OUT OF DATE (old process still running). '
            'Close every Elite window, run START-SWIMIQ-WITH-ELITE.bat, '
            'then confirm /health includes storage_download_configured.';
      } else if (!storageConfigured) {
        message =
            'Elite server is up, but Supabase storage keys are missing in services/video_analysis/.env. '
            'Run START-SWIMIQ-WITH-ELITE.bat again so it copies SUPABASE_URL + SUPABASE_ANON_KEY from swimiq/.env.';
      } else {
        message = 'Elite server ready at $baseUrl';
      }
      return EliteServerHealth(
        reachable: ok,
        status: status,
        engineVersion: version,
        ffmpegAvailable: ffmpeg,
        ffprobeAvailable: ffprobe,
        storageConfigured: storageConfigured,
        message: message,
      );
    } catch (e) {
      return EliteServerHealth(
        reachable: false,
        message:
            'Elite server is OFF at $baseUrl. '
            'Double-click START-SWIMIQ-WITH-ELITE.bat, '
            'leave the Elite black window open, then come back here — this banner refreshes automatically.',
      );
    }
  }

  Future<AnalysisJob> createJob({
    required String videoId,
    required String storagePath,
    String storageBucket = 'swim-videos',
    String? swimmerKey,
    String? displayName,
    String? ageGroup,
    String? stroke,
    int? distanceM,
    String? course,
    String? title,
    String? notes,
    String? targetTrackId,
    bool generateGeminiReport = true,
    Map<String, dynamic>? options,
  }) async {
    final body = <String, dynamic>{
      'video_id': videoId,
      'storage_bucket': storageBucket,
      'storage_path': storagePath,
      if (swimmerKey != null)
        'athlete': {
          'swimmer_key': swimmerKey,
          if (displayName != null) 'display_name': displayName,
          if (ageGroup != null) 'age_group': ageGroup,
        },
      'event': {
        'stroke': _normalizeStroke(stroke),
        if (distanceM != null) 'distance_m': distanceM,
        if (course != null) 'course': course,
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
      },
      'options': {
        ...?options,
        'target_selection_mode':
            targetTrackId != null ? 'track_id' : 'automatic',
        if (targetTrackId != null) 'target_track_id': targetTrackId,
        // Launch defaults: coaching always works; sensors enrich when the
        // phone clip + Elite PC can support them (pose soft-fails safely).
        'generate_gemini_report': generateGeminiReport,
        'attach_evidence_images': true,
        'generate_overlay': false,
        'run_pose_stage': true,
        'run_butterfly_analysis': true,
        'run_underwater_analysis': true,
        'run_turn_analysis': true,
        'run_finish_analysis': true,
      },
    };

    final json = await _requestJson(
      'POST',
      '/v1/analyses',
      body: body,
      expectedStatuses: const {202, 200},
    );
    return AnalysisJob.fromJson(json);
  }

  Future<AnalysisJob> getStatus(String jobId) async {
    final json = await _requestJson('GET', '/v1/analyses/$jobId');
    return AnalysisJob.fromJson(json);
  }

  Future<AnalysisResults> getResults(String jobId) async {
    final json = await _requestJson('GET', '/v1/analyses/$jobId/results');
    return AnalysisResults.fromJson(json);
  }

  Future<AnalysisJob> cancelJob(String jobId) async {
    final json = await _requestJson('POST', '/v1/analyses/$jobId/cancel');
    return AnalysisJob.fromJson({
      ...json,
      'stage': json['status'] ?? 'cancelled',
      'engine_version': json['engine_version'] ?? '',
    });
  }

  Future<AnalysisJob> retryJob(String jobId) async {
    final json = await _requestJson('POST', '/v1/analyses/$jobId/retry');
    return AnalysisJob.fromJson({
      ...json,
      'engine_version': json['engine_version'] ?? '',
      'video_id': json['video_id'],
    });
  }

  Future<void> deleteAnalysis(String jobId) async {
    await _requestJson('DELETE', '/v1/analyses/$jobId');
  }

  Future<void> submitFeedback({
    required String jobId,
    required String message,
    String feedbackType = 'general',
    List<String> incorrectFields = const [],
    Map<String, dynamic> payload = const {},
  }) async {
    await _requestJson(
      'POST',
      '/v1/analyses/$jobId/feedback',
      body: {
        'feedback_type': feedbackType,
        'message': message,
        'incorrect_fields': incorrectFields,
        'payload': payload,
      },
    );
  }

  Future<List<AnalysisJob>> listHistory(String swimmerKey) async {
    final json =
        await _requestJson('GET', '/v1/athletes/$swimmerKey/analyses');
    final jobs = <AnalysisJob>[];
    for (final key in ['jobs', 'remote_jobs']) {
      final list = json[key];
      if (list is! List) continue;
      for (final item in list) {
        if (item is Map) {
          jobs.add(AnalysisJob.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    // Deduplicate by job_id, prefer first (local) entry.
    final seen = <String>{};
    return jobs.where((j) => seen.add(j.jobId)).toList(growable: false);
  }

  Future<String> signedVideoUrl(String jobId) async {
    final json =
        await _requestJson('GET', '/v1/analyses/$jobId/signed-video-url');
    final url = json['signed_url']?.toString();
    if (url == null || url.isEmpty) {
      throw VideoEngineV2Exception(
        userMessageForErrorCode('INVALID_VIDEO'),
        errorCode: 'INVALID_VIDEO',
      );
    }
    return url;
  }

  /// Build a recruiting clip pack + auto-stitched MP4 reel on Elite.
  Future<HighlightReelResult> createHighlightReel({
    required List<Map<String, dynamic>> segments,
    String title = 'Recruiting Highlight Reel',
    int maxClipMs = 6000,
  }) async {
    final json = await _requestJson(
      'POST',
      '/v1/highlight-reels',
      body: {
        'title': title,
        'max_clip_ms': maxClipMs,
        'segments': segments,
      },
      expectedStatuses: const {200},
      timeout: const Duration(seconds: 180),
    );
    return HighlightReelResult.fromJson(json);
  }

  /// Maps backend / HTTP error codes to athlete-facing copy.
  static String userMessageForErrorCode(String? code, {String? fallback}) {
    switch ((code ?? '').toUpperCase()) {
      case 'INVALID_VIDEO':
        return 'This video could not be used for analysis. Try uploading again.';
      case 'UNSUPPORTED_CODEC':
        return 'This video format is not supported. Please upload an MP4 (H.264) file.';
      case 'TARGET_SWIMMER_NOT_FOUND':
        return 'We could not find the target swimmer in this video. Try a clearer side view or pick the swimmer track.';
      case 'TARGET_LOST_EXTENDED':
        return 'We lost sight of the swimmer for too much of this clip. Use a steadier side view with the full body in frame.';
      case 'NO_DETECTIONS':
        return 'We could not detect a swimmer in this video. Film from the side with good light and the full body visible.';
      case 'INSUFFICIENT_POSE':
      case 'POSE_FAILED':
      case 'INSUFFICIENT_POSE_EVIDENCE':
      case 'POSE_DEPS_MISSING':
      case 'POSE_SOFT_SKIP':
        return 'Phone coaching is ready — tap Retry analysis. '
            'Extra pose sensors are optional and will enrich the report when available.';
      case 'SERVER_UNAVAILABLE':
      case 'SERVICE_UNAVAILABLE':
        return 'The analysis service is temporarily unavailable. Please try again shortly.';
      case 'ANALYSIS_FAILED':
        return 'Analysis failed. You can retry if available, or upload a clearer clip.';
      case 'GEMINI_UNAVAILABLE':
      case 'REPORT_UNAVAILABLE':
      case 'GEMINI_REPORT_UNAVAILABLE':
      case 'MISSING_API_KEY':
      case 'GEMINI_ERROR':
      case 'INVALID_API_KEY':
        return 'AI coaching tips are temporarily unavailable. '
            'Please try Analyze again in a few minutes.';
      case 'UPLOAD_FAILED':
        return 'Could not load your video for analysis. '
            'Check your connection, stay signed in, and try again.';
      case 'DOWNLOAD_TIMEOUT':
        return 'Downloading your video timed out. '
            'Check Wi-Fi, stay signed in, and try a shorter clip.';
      case 'FFPROBE_TIMEOUT':
        return 'Could not read this video file. Re-upload as MP4 (H.264) and try again.';
      case 'AUTHENTICATION_EXPIRED':
      case 'UNAUTHORIZED':
      case 'AUTH_REQUIRED':
        return 'Your session expired. Please sign in again to continue.';
      case 'FORBIDDEN':
      case 'NOT_OWNER':
        return 'You do not have access to this analysis.';
      case 'NOT_CANCELLABLE':
        return 'This analysis can no longer be cancelled.';
      case 'NOT_RETRIABLE':
        return 'This analysis cannot be retried. Start a new analysis instead.';
      case 'RESULTS_NOT_READY':
        return 'Results are not ready yet.';
      case 'VIDEO_TOO_LARGE':
        return 'This video is too large. Please upload a shorter or smaller file.';
      case 'INVALID_SEGMENT':
        return 'Tag at least one race moment before building your highlight reel.';
      case 'REEL_BUILD_FAILED':
      case 'FFMPEG_UNAVAILABLE':
        return 'Could not build the highlight reel. Keep Elite running with FFmpeg installed, then try again.';
      default:
        return sanitizeUserFacingError(fallback) ??
            'Something went wrong with video analysis. Please try again.';
    }
  }

  /// Never show torch/mmpose engineer text to athletes/parents.
  static String? sanitizeUserFacingError(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();
    if (lower.contains('pose dependency') ||
        lower.contains('no module named') ||
        lower.contains('torch') ||
        lower.contains('mmcv') ||
        lower.contains('mmpose') ||
        lower.contains('mmengine') ||
        lower.contains('mmdet') ||
        lower.contains('traceback')) {
      return 'Phone coaching is ready — tap Retry analysis to finish this race report.';
    }
    return text;
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Set<int> expectedStatuses = const {200},
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final token = await _accessTokenGetter();
    if (token == null || token.isEmpty) {
      throw VideoEngineV2Exception(
        userMessageForErrorCode('AUTHENTICATION_EXPIRED'),
        errorCode: 'AUTHENTICATION_EXPIRED',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    http.Response response;
    try {
      final Future<http.Response> pending;
      switch (method) {
        case 'GET':
          pending = _client.get(uri, headers: headers);
        case 'POST':
          pending = _client.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'DELETE':
          pending = _client.delete(uri, headers: headers);
        default:
          throw VideoEngineV2Exception(
            'Unsupported HTTP method $method',
            errorCode: 'ANALYSIS_FAILED',
          );
      }
      response = await pending.timeout(timeout);
    } catch (e) {
      if (e is VideoEngineV2Exception) rethrow;
      throw VideoEngineV2Exception(
        'Cannot reach Elite server at $baseUrl$path. '
        'Double-click START-SWIMIQ-WITH-ELITE.bat, leave the Elite window open, '
        'confirm $baseUrl/health loads, then try again. ($e)',
        errorCode: 'SERVER_UNAVAILABLE',
        retriable: true,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      final code =
          response.statusCode == 401 ? 'AUTHENTICATION_EXPIRED' : 'FORBIDDEN';
      throw VideoEngineV2Exception(
        userMessageForErrorCode(code),
        errorCode: code,
        statusCode: response.statusCode,
      );
    }

    Map<String, dynamic> json = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    }

    if (!expectedStatuses.contains(response.statusCode)) {
      final detail = json['detail'];
      String? errorCode;
      String? message;
      var retriable = false;
      if (detail is Map) {
        errorCode = detail['error_code']?.toString();
        message = detail['message']?.toString();
        retriable = detail['retriable'] == true;
      } else if (detail is String) {
        message = detail;
      } else {
        errorCode = json['error_code']?.toString();
        message = json['message']?.toString();
      }

      if (response.statusCode >= 500) {
        errorCode ??= 'SERVER_UNAVAILABLE';
      }
      errorCode ??= 'ANALYSIS_FAILED';

      throw VideoEngineV2Exception(
        userMessageForErrorCode(errorCode, fallback: message),
        errorCode: errorCode,
        statusCode: response.statusCode,
        retriable: retriable,
      );
    }

    return json;
  }

  static String _normalizeStroke(String? stroke) {
    final s = (stroke ?? 'unknown').trim().toLowerCase();
    switch (s) {
      case 'fly':
      case 'butterfly':
        return 'butterfly';
      case 'free':
      case 'freestyle':
        return 'freestyle';
      case 'back':
      case 'backstroke':
        return 'backstroke';
      case 'breast':
      case 'breaststroke':
        return 'breaststroke';
      case 'im':
      case 'individual medley':
        return 'im';
      default:
        return 'unknown';
    }
  }
}

/// Result of pinging the local Elite Video Lab FastAPI `/health` endpoint.
class EliteServerHealth {
  const EliteServerHealth({
    required this.reachable,
    required this.message,
    this.status,
    this.engineVersion,
    this.ffmpegAvailable,
    this.ffprobeAvailable,
    this.storageConfigured = true,
  });

  final bool reachable;
  final String message;
  final String? status;
  final String? engineVersion;
  final bool? ffmpegAvailable;
  final bool? ffprobeAvailable;
  final bool storageConfigured;

  bool get mediaToolsReady =>
      ffmpegAvailable == true && ffprobeAvailable == true;
}

/// Clip pack + auto-stitched recruiting reel from Elite.
class HighlightReelResult {
  const HighlightReelResult({
    required this.reelId,
    required this.title,
    required this.reelUrl,
    required this.downloadToken,
    required this.message,
    required this.clips,
  });

  final String reelId;
  final String title;
  final String reelUrl;
  final String downloadToken;
  final String message;
  final List<HighlightReelClip> clips;

  factory HighlightReelResult.fromJson(Map<String, dynamic> json) {
    final clipsRaw = json['clips'];
    final clips = <HighlightReelClip>[];
    if (clipsRaw is List) {
      for (final item in clipsRaw) {
        if (item is Map) {
          clips.add(HighlightReelClip.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return HighlightReelResult(
      reelId: json['reel_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Recruiting Highlight Reel',
      reelUrl: json['reel_url']?.toString() ?? '',
      downloadToken: json['download_token']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      clips: clips,
    );
  }
}

class HighlightReelClip {
  const HighlightReelClip({
    required this.label,
    required this.tag,
    required this.startMs,
    required this.endMs,
    required this.fileName,
    required this.downloadUrl,
  });

  final String label;
  final String tag;
  final int startMs;
  final int endMs;
  final String fileName;
  final String downloadUrl;

  factory HighlightReelClip.fromJson(Map<String, dynamic> json) {
    return HighlightReelClip(
      label: json['label']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      startMs: (json['start_ms'] as num?)?.round() ?? 0,
      endMs: (json['end_ms'] as num?)?.round() ?? 0,
      fileName: json['file_name']?.toString() ?? '',
      downloadUrl: json['download_url']?.toString() ?? '',
    );
  }
}
