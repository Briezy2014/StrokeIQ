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
        'target_selection_mode':
            targetTrackId != null ? 'track_id' : 'automatic',
        if (targetTrackId != null) 'target_track_id': targetTrackId,
        'generate_gemini_report': generateGeminiReport,
        'generate_overlay': true,
        'run_pose_stage': true,
        'run_butterfly_analysis': true,
        'run_underwater_analysis': true,
        'run_turn_analysis': true,
        'run_finish_analysis': true,
        ...?options,
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

  /// Maps backend / HTTP error codes to athlete-facing copy.
  static String userMessageForErrorCode(String? code, {String? fallback}) {
    switch ((code ?? '').toUpperCase()) {
      case 'INVALID_VIDEO':
        return 'This video could not be used for analysis. Try uploading again.';
      case 'UNSUPPORTED_CODEC':
        return 'This video format is not supported. Please upload an MP4 (H.264) file.';
      case 'TARGET_SWIMMER_NOT_FOUND':
        return 'We could not find the target swimmer in this video. Try a clearer side view or pick the swimmer track.';
      case 'INSUFFICIENT_POSE':
      case 'POSE_FAILED':
      case 'INSUFFICIENT_POSE_EVIDENCE':
        return 'Not enough clear pose data was detected to measure technique confidently.';
      case 'SERVER_UNAVAILABLE':
      case 'SERVICE_UNAVAILABLE':
        return 'The analysis service is temporarily unavailable. Please try again shortly.';
      case 'ANALYSIS_FAILED':
        return 'Analysis failed. You can retry if available, or upload a clearer clip.';
      case 'GEMINI_UNAVAILABLE':
      case 'REPORT_UNAVAILABLE':
      case 'GEMINI_REPORT_UNAVAILABLE':
        return 'Coaching report is unavailable right now. Measured metrics are still shown when present.';
      case 'UPLOAD_FAILED':
        return 'Video upload failed. Check your connection and try again.';
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
      default:
        return fallback?.trim().isNotEmpty == true
            ? fallback!.trim()
            : 'Something went wrong with video analysis. Please try again.';
    }
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Set<int> expectedStatuses = const {200},
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
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
        default:
          throw VideoEngineV2Exception(
            'Unsupported HTTP method $method',
            errorCode: 'ANALYSIS_FAILED',
          );
      }
    } catch (e) {
      if (e is VideoEngineV2Exception) rethrow;
      throw VideoEngineV2Exception(
        userMessageForErrorCode('SERVER_UNAVAILABLE'),
        errorCode: 'SERVER_UNAVAILABLE',
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
