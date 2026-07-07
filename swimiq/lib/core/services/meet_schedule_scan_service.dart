import 'dart:convert';
import 'dart:typed_data';

import 'package:functions_client/functions_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/scheduled_meet.dart';

class MeetScheduleScanException implements Exception {
  MeetScheduleScanException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sends a meet-schedule photo to Gemini via Supabase Edge Function.
class MeetScheduleScanService {
  MeetScheduleScanService(this._client);

  static const functionName = 'parse-meet-schedule';
  static const maxBytes = 8 * 1024 * 1024;

  final SupabaseClient _client;

  Future<List<ScheduledMeet>> parseScheduleImage({
    required Uint8List bytes,
    required String fileName,
    String? teamName,
  }) async {
    if (bytes.length > maxBytes) {
      throw MeetScheduleScanException(
        'Photo is too large (max 8 MB). Try a closer crop of the schedule.',
      );
    }

    final mimeType = _mimeTypeForFileName(fileName);
    final imageBase64 = base64Encode(bytes);

    try {
      final response = await _client.functions.invoke(
        functionName,
        body: {
          'image_base64': imageBase64,
          'mime_type': mimeType,
          'file_name': fileName,
          if (teamName != null && teamName.isNotEmpty) 'team_name': teamName,
        },
      );

      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw MeetScheduleScanException(data['error'].toString());
      }
      if (data is! Map) {
        throw MeetScheduleScanException('Unexpected response from $functionName.');
      }

      return parseMeetsResponse(Map<String, dynamic>.from(data));
    } on FunctionException catch (error) {
      throw MeetScheduleScanException(_messageFromFunctionException(error));
    }
  }

  static List<ScheduledMeet> parseMeetsResponse(Map<String, dynamic> data) {
    final meetsRaw = data['meets'];
    if (meetsRaw is! List) return const [];

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final meets = meetsRaw
        .whereType<Map>()
        .map((m) => ScheduledMeet.fromScanJson(Map<String, dynamic>.from(m)))
        .where((m) => !m.startDate.isBefore(startOfToday))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return meets;
  }

  static String _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  static String _messageFromFunctionException(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    if (error.status == 404) {
      return 'Meet schedule scan is not deployed yet. Deploy parse-meet-schedule '
          'to Supabase Edge Functions.';
    }
    if (error.status == 503) {
      return 'Gemini is not configured. Set GEMINI_API_KEY in Supabase secrets.';
    }
    return error.reasonPhrase ??
        'Could not read meet schedule (HTTP ${error.status}).';
  }
}
