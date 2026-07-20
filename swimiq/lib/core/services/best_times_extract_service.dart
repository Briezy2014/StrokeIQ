import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env.dart';
import '../utils/best_times_event_parser.dart';

class BestTimesExtractException implements Exception {
  BestTimesExtractException(this.message, {this.errorCode});

  final String message;
  final String? errorCode;

  @override
  String toString() => message;
}

/// Reads many PB rows from a Best Times History screenshot.
///
/// Tries, in order:
/// 1) Local Elite (`/v1/extract-best-times`) when `/health` is up — long timeout
/// 2) Dedicated Edge Function `extract-best-times`
/// 3) Already-deployed `analyze-swim-video` with `extract_best_times: true`
class BestTimesExtractService {
  BestTimesExtractService({
    http.Client? client,
    SupabaseClient? supabase,
    String? eliteBaseUrl,
  })  : _client = client ?? http.Client(),
        _supabase = supabase ?? Supabase.instance.client,
        _eliteBaseUrl = eliteBaseUrl;

  static const edgeFunctionName = 'extract-best-times';
  static const analyzeFunctionName = 'analyze-swim-video';
  static const eliteTimeout = Duration(seconds: 90);
  static const edgeTimeout = Duration(seconds: 90);

  final http.Client _client;
  final SupabaseClient _supabase;
  final String? _eliteBaseUrl;

  Future<BestTimesExtractResponse> extractFromPhoto({
    required Uint8List bytes,
    required String fileName,
    String? courseHint,
  }) async {
    final mime = _mimeFromName(fileName);
    final imageBase64 = base64Encode(bytes);
    final errors = <String>[];

    // 1) Local Elite — preferred on Windows when START-SWIMIQ-WITH-ELITE is open.
    if (await _eliteHealthOk()) {
      try {
        return await _extractViaElite(
          imageBase64: imageBase64,
          mimeType: mime,
          courseHint: courseHint,
        );
      } on BestTimesExtractException catch (e) {
        if (e.errorCode == 'AUTH_REQUIRED' ||
            e.errorCode == 'NO_TIMES_FOUND' ||
            e.errorCode == 'BAD_RESPONSE') {
          rethrow;
        }
        errors.add('Elite: ${e.message}');
      } catch (e) {
        errors.add('Elite: $e');
      }
    } else {
      errors.add(
        'Elite: not running on ${Env.analysisApiBaseUrl} '
        '(start START-SWIMIQ-WITH-ELITE.bat).',
      );
    }

    // 2) Dedicated extract-best-times Edge Function.
    try {
      return await _extractViaEdge(
        functionName: edgeFunctionName,
        imageBase64: imageBase64,
        mimeType: mime,
        courseHint: courseHint,
      );
    } on BestTimesExtractException catch (e) {
      if (e.errorCode == 'AUTH_REQUIRED' ||
          e.errorCode == 'NO_TIMES_FOUND' ||
          e.errorCode == 'BAD_RESPONSE') {
        rethrow;
      }
      errors.add('Cloud extract-best-times: ${e.message}');
    } catch (e) {
      errors.add('Cloud extract-best-times: $e');
    }

    // 3) analyze-swim-video (usually already deployed with GEMINI_API_KEY).
    try {
      return await _extractViaEdge(
        functionName: analyzeFunctionName,
        imageBase64: imageBase64,
        mimeType: mime,
        courseHint: courseHint,
        viaAnalyzeSwimVideo: true,
      );
    } on BestTimesExtractException catch (e) {
      if (e.errorCode == 'AUTH_REQUIRED' ||
          e.errorCode == 'NO_TIMES_FOUND' ||
          e.errorCode == 'BAD_RESPONSE') {
        rethrow;
      }
      errors.add('Cloud analyze-swim-video: ${e.message}');
    } catch (e) {
      errors.add('Cloud analyze-swim-video: $e');
    }

    throw BestTimesExtractException(
      _combinedFailureMessage(errors),
      errorCode: 'EXTRACT_FAILED',
    );
  }

  static String _combinedFailureMessage(List<String> errors) {
    return combinedFailureMessageForTest(errors);
  }

  /// Exposed for unit tests.
  static String combinedFailureMessageForTest(List<String> errors) {
    return 'Could not read best times from this photo.\n\n'
        'Do this once:\n'
        '1. Double-click swimiq\\DEPLOY-EXTRACT-BEST-TIMES.bat '
        '(needs GEMINI_API_KEY in Supabase Edge secrets), OR\n'
        '2. Keep START-SWIMIQ-WITH-ELITE.bat open with GEMINI_API_KEY in '
        'services\\video_analysis\\.env, then retry '
        '(reading a full Best Times page can take up to a minute).\n\n'
        '${errors.join('\n')}';
  }

  Future<bool> _eliteHealthOk() async {
    final base = (_eliteBaseUrl ?? Env.analysisApiBaseUrl).trim();
    if (base.isEmpty) return false;
    try {
      final response = await _client
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<BestTimesExtractResponse> _extractViaElite({
    required String imageBase64,
    required String mimeType,
    String? courseHint,
  }) async {
    final base = (_eliteBaseUrl ?? Env.analysisApiBaseUrl).trim();
    if (base.isEmpty) {
      throw BestTimesExtractException(
        'Elite analysis server is not configured.',
        errorCode: 'SERVER_UNAVAILABLE',
      );
    }
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw BestTimesExtractException(
        'Sign in to extract times from a photo.',
        errorCode: 'AUTH_REQUIRED',
      );
    }

    final uri = Uri.parse('$base/v1/extract-best-times');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'image_base64': imageBase64,
              'mime_type': mimeType,
              if (courseHint != null) 'course_hint': courseHint,
            }),
          )
          .timeout(eliteTimeout);
    } on Exception catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('timeout') || text.contains('timed out')) {
        throw BestTimesExtractException(
          'Elite is still reading the photo (timed out after '
          '${eliteTimeout.inSeconds}s). Keep Elite open and retry — '
          'large Best Times screenshots can take a minute.',
          errorCode: 'TIMEOUT',
        );
      }
      throw BestTimesExtractException(
        'Could not reach the Elite server to read this photo.',
        errorCode: 'SERVER_UNAVAILABLE',
      );
    }

    return _parseHttpResponse(response);
  }

  Future<BestTimesExtractResponse> _extractViaEdge({
    required String functionName,
    required String imageBase64,
    required String mimeType,
    String? courseHint,
    bool viaAnalyzeSwimVideo = false,
  }) async {
    FunctionResponse response;
    try {
      response = await _supabase.functions
          .invoke(
            functionName,
            body: {
              if (viaAnalyzeSwimVideo) 'extract_best_times': true,
              'image_base64': imageBase64,
              'mime_type': mimeType,
              if (courseHint != null) 'course_hint': courseHint,
            },
          )
          .timeout(edgeTimeout);
    } on FunctionException catch (e) {
      final details = e.details;
      String message = 'Cloud photo reader failed (${e.status}).';
      if (details is Map) {
        message = (details['message'] ?? details['error'] ?? message).toString();
      } else if (details != null) {
        message = details.toString();
      }
      if (e.status == 404 || message.toLowerCase().contains('not found')) {
        throw BestTimesExtractException(
          'Cloud photo reader "$functionName" is not deployed yet. '
          'Run swimiq\\DEPLOY-EXTRACT-BEST-TIMES.bat',
          errorCode: 'EDGE_NOT_DEPLOYED',
        );
      }
      if (message.toLowerCase().contains('storage_path is required')) {
        throw BestTimesExtractException(
          'Cloud video function is outdated for photo upload. '
          'Run swimiq\\DEPLOY-EXTRACT-BEST-TIMES.bat to update analyze-swim-video.',
          errorCode: 'EDGE_OUTDATED',
        );
      }
      throw BestTimesExtractException(
        _friendlyExtractMessage(message),
        errorCode: 'EDGE_FAILED',
      );
    } on Exception catch (e) {
      final text = e.toString();
      if (text.toLowerCase().contains('failed to fetch') ||
          text.toLowerCase().contains('clientexception')) {
        throw BestTimesExtractException(
          'Could not reach cloud function "$functionName" (not deployed or network). '
          'Run swimiq\\DEPLOY-EXTRACT-BEST-TIMES.bat',
          errorCode: 'EDGE_NOT_DEPLOYED',
        );
      }
      throw BestTimesExtractException(
        _friendlyExtractMessage(text),
        errorCode: 'EDGE_FAILED',
      );
    }

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map
          ? (data['message'] ?? data['error'] ?? 'Photo extract failed')
              .toString()
          : 'Photo extract failed (${response.status}).';
      if (message.toLowerCase().contains('storage_path is required')) {
        throw BestTimesExtractException(
          'Cloud video function is outdated for photo upload. '
          'Run swimiq\\DEPLOY-EXTRACT-BEST-TIMES.bat to update analyze-swim-video.',
          errorCode: 'EDGE_OUTDATED',
        );
      }
      throw BestTimesExtractException(
        _friendlyExtractMessage(message),
        errorCode: 'EDGE_FAILED',
      );
    }
    final data = response.data;
    if (data is! Map) {
      throw BestTimesExtractException(
        'Unexpected response from photo extract.',
        errorCode: 'BAD_RESPONSE',
      );
    }
    final parsed =
        BestTimesExtractResponse.fromJson(Map<String, dynamic>.from(data));
    if (parsed.times.isEmpty) {
      throw BestTimesExtractException(
        'No swim times were found in that photo.',
        errorCode: 'NO_TIMES_FOUND',
      );
    }
    return parsed;
  }

  BestTimesExtractResponse _parseHttpResponse(http.Response response) {
    Map<String, dynamic>? map;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) map = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300 && map != null) {
      final parsed = BestTimesExtractResponse.fromJson(map);
      if (parsed.times.isEmpty) {
        throw BestTimesExtractException(
          'No swim times were found in that photo.',
          errorCode: 'NO_TIMES_FOUND',
        );
      }
      return parsed;
    }

    final detail = map?['detail'];
    if (detail is Map) {
      throw BestTimesExtractException(
        _friendlyExtractMessage(
          (detail['message'] ?? 'Could not read best times from photo.')
              .toString(),
        ),
        errorCode: detail['error_code']?.toString(),
      );
    }
    final mapError = map?['error']?.toString() ?? map?['message']?.toString();
    if (mapError != null && mapError.trim().isNotEmpty) {
      throw BestTimesExtractException(
        _friendlyExtractMessage(mapError),
        errorCode: 'EXTRACT_FAILED',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw BestTimesExtractException(
        'Sign in to extract times from a photo.',
        errorCode: 'AUTH_REQUIRED',
      );
    }
    if (response.statusCode == 0 || response.statusCode >= 500) {
      throw BestTimesExtractException(
        'Could not reach the Elite server to read this photo.',
        errorCode: 'SERVER_UNAVAILABLE',
      );
    }
    throw BestTimesExtractException(
      _friendlyExtractMessage(
        detail?.toString() ??
            'Could not read best times from photo (${response.statusCode}).',
      ),
      errorCode: 'EXTRACT_FAILED',
    );
  }

  static String _friendlyExtractMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('no longer available') ||
        lower.contains('not_found') ||
        lower.contains('gemini-2.5-flash') ||
        lower.contains('gemini-2.0-flash')) {
      return 'Google retired the old Gemini model for photo reading. '
          'Redeploy with DEPLOY-EXTRACT-BEST-TIMES.bat or restart Elite.';
    }
    if (lower.contains('missing_api_key') ||
        lower.contains('gemini_api_key is not configured')) {
      return 'Add GEMINI_API_KEY to Supabase Edge Function secrets '
          '(and services/video_analysis/.env for local Elite), then retry.';
    }
    if (lower.contains('failed to fetch') ||
        lower.contains('clientexception') ||
        lower.contains('network')) {
      return 'Network error talking to the photo reader. '
          'Deploy functions or start Elite, then retry.';
    }
    return raw;
  }

  static String _mimeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
