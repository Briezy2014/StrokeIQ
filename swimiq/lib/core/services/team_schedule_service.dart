import 'package:functions_client/functions_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/scheduled_meet.dart';

class TeamScheduleSyncResult {
  const TeamScheduleSyncResult({
    required this.meets,
    this.teamName,
    this.pdfLinks = const [],
    this.source,
  });

  final List<ScheduledMeet> meets;
  final String? teamName;
  final List<TeamSchedulePdfLink> pdfLinks;
  final String? source;
}

class TeamSchedulePdfLink {
  const TeamSchedulePdfLink({
    required this.label,
    required this.url,
    this.updated,
  });

  final String label;
  final String url;
  final String? updated;

  factory TeamSchedulePdfLink.fromJson(Map<String, dynamic> json) {
    return TeamSchedulePdfLink(
      label: json['label']?.toString() ?? 'Meet schedule PDF',
      url: json['url']?.toString() ?? '',
      updated: json['updated']?.toString(),
    );
  }
}

/// Pulls Central Ohio Aquatics meet schedule via Supabase Edge Function
/// (avoids browser CORS on SportsEngine / GoMotion).
class TeamScheduleService {
  TeamScheduleService(this._client);

  static const functionName = 'sync-coa-team-schedule';

  final SupabaseClient _client;

  Future<TeamScheduleSyncResult> syncCoaSchedule() async {
    try {
      final response = await _client.functions.invoke(functionName, body: {});
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw TeamScheduleException(data['error'].toString());
      }
      if (data is! Map) {
        throw TeamScheduleException('Unexpected response from $functionName.');
      }
      return parseSyncResponse(Map<String, dynamic>.from(data));
    } on FunctionException catch (error) {
      throw TeamScheduleException(_messageFromFunctionException(error));
    }
  }

  static TeamScheduleSyncResult parseSyncResponse(Map<String, dynamic> data) {
    final events = data['events'];
    final meets = <ScheduledMeet>[];
    if (events is List) {
      for (final item in events) {
        if (item is Map) {
          meets.add(
            ScheduledMeet.fromCoaTeamEvent(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    meets.sort((a, b) => a.startDate.compareTo(b.startDate));

    final pdfRaw = data['pdf_links'];
    final pdfLinks = <TeamSchedulePdfLink>[];
    if (pdfRaw is List) {
      for (final item in pdfRaw) {
        if (item is Map) {
          pdfLinks.add(
            TeamSchedulePdfLink.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return TeamScheduleSyncResult(
      meets: meets,
      teamName: data['team']?.toString(),
      pdfLinks: pdfLinks,
      source: data['source']?.toString(),
    );
  }

  static String _messageFromFunctionException(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    if (error.status == 404) {
      return 'COA schedule sync is not deployed yet. Deploy sync-coa-team-schedule '
          'to Supabase Edge Functions.';
    }
    return error.reasonPhrase ??
        'Could not load COA team schedule (HTTP ${error.status}).';
  }
}

class TeamScheduleException implements Exception {
  TeamScheduleException(this.message);

  final String message;

  @override
  String toString() => message;
}
