import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/motivational_standard.dart';

/// Query layer for the shared `motivational_standards` Supabase table.
class MotivationalStandardsRepository {
  MotivationalStandardsRepository(this._client);

  final SupabaseClient _client;

  Future<List<MotivationalStandard>> fetchStandards({
    String? version,
    String? ageGroup,
    String? gender,
    String? course,
    String? eventQuery,
  }) async {
    var query = _client.from(AppConstants.motivationalStandardsTable).select();

    final resolvedVersion = version ?? AppConstants.defaultStandardsVersion;
    query = query.eq('version', resolvedVersion);

    if (ageGroup != null && ageGroup.isNotEmpty) {
      query = query.eq('age_group', ageGroup);
    }
    if (gender != null && gender.isNotEmpty) {
      query = query.eq('gender', gender);
    }
    if (course != null && course.isNotEmpty) {
      query = query.eq('course', course);
    }
    if (eventQuery != null && eventQuery.trim().isNotEmpty) {
      query = query.ilike('event', '%${eventQuery.trim()}%');
    }

    final response = await query.order('event').order('age_group');

    return (response as List<dynamic>)
        .map((row) => MotivationalStandard.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MotivationalStandard?> fetchStandardForEvent({
    required String ageGroup,
    required String gender,
    required String course,
    required String event,
    String? version,
  }) async {
    final resolvedVersion = version ?? AppConstants.defaultStandardsVersion;

    final response = await _client
        .from(AppConstants.motivationalStandardsTable)
        .select()
        .eq('version', resolvedVersion)
        .eq('age_group', ageGroup)
        .eq('gender', gender)
        .eq('course', course)
        .eq('event', event)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return MotivationalStandard.fromJson(response);
  }

  Future<List<String>> fetchVersions() async {
    final response = await _client
        .from(AppConstants.motivationalStandardsTable)
        .select('version');

    final versions = <String>{};
    for (final row in response as List<dynamic>) {
      final version = (row as Map<String, dynamic>)['version'] as String?;
      if (version != null) {
        versions.add(version);
      }
    }

    return versions.toList()..sort();
  }

  Future<int> countStandards({String? version}) async {
    final resolvedVersion = version ?? AppConstants.defaultStandardsVersion;

    final response = await _client
        .from(AppConstants.motivationalStandardsTable)
        .select('id')
        .eq('version', resolvedVersion)
        .count(CountOption.exact);

    return response.count;
  }
}
