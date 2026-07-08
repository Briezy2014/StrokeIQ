import '../../data/models/swim_video_analysis.dart';

/// Keeps AI swim analysis supportive and appropriate for youth + parents.
abstract final class YouthFriendlyAnalysis {
  static const audienceNote =
      'Kid- and parent-friendly coaching — swim technique only, not medical advice.';

  static final _blockedPattern = RegExp(
    r'\b(sexy|hot body|ugly|fat|obese|overweight|skinny|stupid|idiot|'
    r'hate you|kill it|damn|hell|shit|fuck|wtf|sucks at)\b',
    caseSensitive: false,
  );

  static String sanitize(String? text) {
    if (text == null) return '';
    var value = text.trim();
    if (value.isEmpty) return '';
    if (_blockedPattern.hasMatch(value)) {
      value = value.replaceAll(_blockedPattern, '');
    }
    value = value
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return value;
  }

  static SwimVideoAnalysis sanitizeAnalysis(SwimVideoAnalysis analysis) {
    final json = analysis.analysisJson == null
        ? null
        : Map<String, dynamic>.from(analysis.analysisJson!);

    if (json != null && json['sections'] is Map) {
      final sections = Map<String, dynamic>.from(json['sections'] as Map);
      final cleaned = <String, dynamic>{};
      for (final entry in sections.entries) {
        final body = sanitize(entry.value?.toString());
        if (body.isNotEmpty) cleaned[entry.key] = body;
      }
      json['sections'] = cleaned;
      for (final key in [
        'quick_pro',
        'quick_con',
        'next_race_goal',
        'dryland_focus',
        'estimated_time_savings',
        'coach_notes_for_next_race',
      ]) {
        if (json[key] != null) {
          json[key] = sanitize(json[key]?.toString());
        }
      }
      if (json['top_3_priorities'] is List) {
        json['top_3_priorities'] = (json['top_3_priorities'] as List)
            .map((item) => sanitize(item?.toString()))
            .where((item) => item.isNotEmpty)
            .toList();
      }
      json['youth_friendly'] = true;
    }

    return analysis.copyWith(
      summary: sanitize(analysis.summary),
      strengths: sanitize(analysis.strengths),
      improvements: sanitize(analysis.improvements),
      analysisJson: json,
    );
  }
}
