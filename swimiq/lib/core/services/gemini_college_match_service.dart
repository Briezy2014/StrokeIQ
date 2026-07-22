import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/personal_best_entry.dart';
import '../../data/models/swimmer_profile.dart';
import '../utils/swim_time.dart';
import 'college_recruiting_benchmark_catalog.dart';

/// Calls Gemini to summarize benchmark-matched schools (no invented programs).
class GeminiCollegeMatchService {
  GeminiCollegeMatchService(this._client);

  static const functionName = 'match-college-recruiting';

  final SupabaseClient _client;

  Future<String?> summarizeMatches({
    required SwimmerProfile? profile,
    required List<PersonalBestEntry> personalBests,
    required List<CollegeSchoolMatch> matches,
    required String benchmarkDisclaimer,
  }) async {
    if (matches.isEmpty) return null;

    final response = await _client.functions.invoke(
      functionName,
      body: {
        'display_name': profile?.displayName ?? profile?.swimmerName,
        'graduation_year': profile?.graduationYear,
        'gpa': profile?.gpa,
        'college_interests': profile?.collegeInterests,
        'personal_bests': personalBests
            .take(6)
            .map(
              (pb) =>
                  '${pb.displayTitle} ${pb.course} ${SwimTime.fromSeconds(pb.timeSeconds)}',
            )
            .toList(),
        'benchmark_disclaimer': benchmarkDisclaimer,
        'matches': matches
            .take(12)
            .map(
              (match) => {
                'school': match.school,
                'division': match.division,
                'conference': match.conference,
                'tier': match.tierLabel,
                'event': match.eventLabel,
                'swimmer_time': SwimTime.fromSeconds(match.swimmerTimeSeconds),
                'recruit_range':
                    '${SwimTime.fromSeconds(match.reachSeconds)}–${SwimTime.fromSeconds(match.likelySeconds)}',
                'gap_to_target': SwimTime.fromSeconds(
                  match.gapToTargetSeconds.abs(),
                ),
              },
            )
            .toList(),
      },
    );

    if (response.status != 200) return null;
    final data = response.data;
    if (data is! Map) return null;
    if (data['error'] != null) return null;
    return data['coach_summary']?.toString();
  }
}
