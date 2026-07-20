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
/// Prefer the Supabase Edge Function (works on swimiqapp.com and local without
/// Elite). Fall back to the local Elite Gemini endpoint when the cloud path
/// is unavailable.
class BestTimesExtractService {
  BestTimesExtractService({
    http.Client? client,
    SupabaseClient? supabase,
    String? eliteBaseUrl,
  })  : _client = client ?? http.Client(),
        _supabase = supabase ?? Supabase.instance.client,
        _eliteBaseUrl = eliteBaseUrl;

  static const edgeFunctionName = 'extract-best-times';

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

    BestTimesExtractException? edgeError;
    try {
      return await _extractViaEdge(
        imageBase64: imageBase64,
        mimeType: mime,
        courseHint: courseHint,
      );
    } on BestTimesExtractException catch (e) {
      // Auth / empty-photo errors should not silently fall through to Elite.
      if (e.errorCode == 'AUTH_REQUIRED' ||
          e.errorCode == 'NO_TIMES_FOUND' ||
          e.errorCode == 'BAD_RESPONSE') {
        rethrow;
      }
      edgeError = e;
    } catch (e) {
      edgeError = BestTimesExtractException(
        'Cloud photo reader failed: $e',
        errorCode: 'EDGE_FAILED',
      );
    }

    BestTimesExtractException? eliteError;
    try {
      return await _extractViaElite(
        imageBase64: imageBase64,
        mimeType: mime,
        courseHint: courseHint,
      );
    } on BestTimesExtractException catch (e) {
      eliteError = e;
    } catch (e) {
      eliteError = BestTimesExtractException(
        'Could not reach the Elite server to read this photo.',
        errorCode: 'SERVER_UNAVAILABLE',
      );
    }

    throw BestTimesExtractException(
      _combinedFailureMessage(edgeError: edgeError, eliteError: eliteError),
      errorCode: edgeError.errorCode ?? eliteError.errorCode ?? 'EXTRACT_FAILED',
    );
  }

  static String _combinedFailureMessage({
    BestTimesExtractException? edgeError,
    BestTimesExtractException? eliteError,
  }) {
    final edge = edgeError?.message.trim() ?? '';
    final elite = eliteError?.message.trim() ?? '';
    if (edge.isNotEmpty &&
        (edge.toLowerCase().contains('gemini') ||
            edge.toLowerCase().contains('not configured') ||
            edge.toLowerCase().contains('deploy'))) {
      return edge;
    }
    if (elite.isNotEmpty &&
        eliteError?.errorCode != 'SERVER_UNAVAILABLE' &&
        !elite.toLowerCase().contains('could not reach')) {
      return elite;
    }
    return 'Could not read best times from this photo. '
        'Try a clearer screenshot, or enter times manually. '
        'If it keeps failing, email support@swimiqapp.com.';
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

    final uri = Uri.parse(
      '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}'
      '/v1/extract-best-times',
    );
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
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      throw BestTimesExtractException(
        'Could not reach the Elite server to read this photo.',
        errorCode: 'SERVER_UNAVAILABLE',
      );
    }

    return _parseHttpResponse(response);
  }

  Future<BestTimesExtractResponse> _extractViaEdge({
    required String imageBase64,
    required String mimeType,
    String? courseHint,
  }) async {
    FunctionResponse response;
    try {
      response = await _supabase.functions.invoke(
        edgeFunctionName,
        body: {
          'image_base64': imageBase64,
          'mime_type': mimeType,
          if (courseHint != null) 'course_hint': courseHint,
        },
      );
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
          'Photo import is temporarily unavailable. '
          'Please try again later or enter times manually.',
          errorCode: 'EDGE_NOT_DEPLOYED',
        );
      }
      throw BestTimesExtractException(
        _friendlyExtractMessage(message),
        errorCode: 'EDGE_FAILED',
      );
    }

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map
          ? (data['message'] ?? data['error'] ?? 'Photo extract failed')
              .toString()
          : 'Photo extract failed (${response.status}).';
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
        lower.contains('gemini-2.0-flash') ||
        lower.contains('missing_api_key') ||
        lower.contains('gemini_api_key')) {
      return 'Photo import is temporarily unavailable. '
          'Try again shortly, or enter times manually.';
    }
    if (lower.contains('failed to fetch') ||
        lower.contains('clientexception') ||
        lower.contains('network')) {
      return 'Network error reading this photo. Check Wi‑Fi and try again.';
    }
    if (lower.contains('.bat') ||
        lower.contains('supabase') ||
        lower.contains('127.0.0.1')) {
      return 'Could not read best times from this photo. '
          'Try a clearer image or enter times manually.';
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
