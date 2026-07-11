import '../../data/models/swim_video_analysis.dart';
import 'youth_coaching_phrases.dart';

/// Keeps AI swim analysis supportive and appropriate for youth + parents.
abstract final class YouthFriendlyAnalysis {
  static const audienceNote =
      'Kid- and parent-friendly coaching — we explain swim words in plain language. '
      'Not medical advice; confirm with your coach.';

  static final _blockedPattern = RegExp(
    r'\b(sexy|hot body|ugly|fat|obese|overweight|skinny|stupid|idiot|'
    r'hate you|kill it|damn|hell|shit|fuck|wtf|sucks at)\b',
    caseSensitive: false,
  );

  static final _plainLanguageReplacements = <_PlainLanguageRule>[
    _PlainLanguageRule(
      RegExp(
        r'drive full extension on the last stroke at the wall\.?',
        caseSensitive: false,
      ),
      YouthCoachingPhrases.finishFocusPriority,
    ),
    _PlainLanguageRule(
      RegExp(
        r'full extension into the wall on the last stroke',
        caseSensitive: false,
      ),
      'a complete last stroke with a long reach to the wall',
    ),
    _PlainLanguageRule(
      RegExp(
        r'drove full extension into the wall',
        caseSensitive: false,
      ),
      'finished with a complete last stroke — long reach and a strong touch',
    ),
    _PlainLanguageRule(
      RegExp(r'\bfull extension\b', caseSensitive: false),
      'a complete last stroke with your arm stretched out long',
    ),
    _PlainLanguageRule(
      RegExp(r'hold streamline longer before breakout\.?', caseSensitive: false),
      YouthCoachingPhrases.holdStreamlinePriority,
    ),
    _PlainLanguageRule(
      RegExp(r'\bbreakout\b', caseSensitive: false),
      'coming up for your first stroke after underwater',
    ),
    _PlainLanguageRule(
      RegExp(r'over-gliding', caseSensitive: false),
      'pausing too long with your arms stretched out',
    ),
    _PlainLanguageRule(
      RegExp(r'body line', caseSensitive: false),
      'flat body position on the water',
    ),
    _PlainLanguageRule(
      RegExp(r'high-elbow catch', caseSensitive: false),
      'pull with your elbow high, like scooping water with your forearm',
    ),
  ];

  static String plainLanguage(String? text) {
    if (text == null) return '';
    var value = text.trim();
    if (value.isEmpty) return '';

    for (final rule in _plainLanguageReplacements) {
      value = value.replaceAll(rule.pattern, rule.replacement);
    }

    return value
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String sanitize(String? text) {
    if (text == null) return '';
    var value = plainLanguage(text);
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

class _PlainLanguageRule {
  const _PlainLanguageRule(this.pattern, this.replacement);

  final RegExp pattern;
  final String replacement;
}
