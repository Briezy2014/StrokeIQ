import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swim_time.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/usa_time_standard.dart';
import '../../data/models/video_models.dart';
import '../../data/models/swimmer_profile.dart';

/// Notes-driven V1 coaching analysis. Output is grounded in user notes only.
class AiSwimAnalysisService {
  static const disclaimer =
      'V1 coaching analysis based on video metadata and user notes, '
      'not automated frame-by-frame computer vision yet.';

  static const _sectionKeywords = <String, List<String>>{
    'Reaction / dive': [
      'reaction',
      'reaction time',
      'dive',
      'start',
      'block',
      'entry',
      'explosive',
    ],
    'Breakout': [
      'breakout',
      'surface',
      'first stroke',
      'break out',
      'pop up',
    ],
    'Breathing': [
      'breath',
      'breathing',
      'breath timing',
    ],
    'Stroke count': [
      'stroke count',
      'strokes per',
      'strokes/length',
      'spl',
    ],
    'Tempo': [
      'tempo',
      'rhythm',
      'cadence',
      'rate',
      'stroke length',
      'cycles',
    ],
    'Finish': [
      'finish',
      'touch',
      'wall',
      'glide',
      'final',
      'lunge',
      'extension',
      'last 15',
    ],
  };

  SwimVideoAnalysis analyze({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
    List<UsaTimeStandard> standards = const [],
  }) {
    final eventLabel = video.eventLabel;
    final stroke = SwimStrokeUtils.canonical(
      video.stroke ?? profile?.primaryStroke ?? 'Freestyle',
    );
    final distance = video.distanceMeters ?? 100;
    final course = video.course ?? 'SCY';
    final notes = video.notes?.trim() ?? '';
    final clauses = _noteClauses(notes);

    final matchingLogs = raceLogs.where(
      (log) =>
          SwimStrokeUtils.matches(log.stroke, stroke) &&
          log.distance == distance &&
          log.course == course,
    );
    final pb = matchingLogs.isEmpty
        ? null
        : matchingLogs
            .map((log) => log.timeSeconds)
            .reduce((a, b) => a < b ? a : b);

    final sections = <String, String>{};
    for (final entry in _sectionKeywords.entries) {
      final matched = _matchedClauses(clauses, entry.value);
      if (matched.isNotEmpty) {
        sections[entry.key] =
            'From your notes for $eventLabel: ${matched.join(' ')}';
      }
    }

    final usaStandards = _usaStandardsSection(
      eventLabel: eventLabel,
      stroke: stroke,
      distance: distance,
      course: course,
      swimmerTime: pb,
      standards: standards,
      profile: profile,
    );

    final priorities = _topPriorities(
      eventLabel: eventLabel,
      clauses: clauses,
      sections: sections,
    );

    final techniqueScore = _scoreFromNotes(notes, clauses.length, sections);
    final paceScore =
        pb != null ? (techniqueScore + 5).clamp(40, 95) : techniqueScore;
    final overallScore = ((techniqueScore + paceScore) / 2).round();

    final summary = StringBuffer()
      ..writeln('Event: $eventLabel')
      ..writeln(disclaimer);
    if (notes.isNotEmpty) {
      summary.writeln('Your notes: $notes');
    } else {
      summary.writeln(
        'Add race-specific notes on the upload form to generate coaching feedback.',
      );
    }

    final strengths = sections.isEmpty
        ? 'Add race notes covering reaction, breakout, breathing, stroke count, tempo, and finish.'
        : _formatSections(sections);

    final improvements = StringBuffer();
    if (priorities.isNotEmpty) {
      improvements.writeln('Top priorities from your notes');
      improvements.write(priorities.map((p) => '• $p').join('\n'));
    }

    return SwimVideoAnalysis(
      swimVideoId: video.id,
      swimmer: video.swimmer,
      summary: summary.toString().trim(),
      strengths: strengths,
      improvements: improvements.toString().trim(),
      techniqueScore: techniqueScore,
      paceScore: paceScore,
      overallScore: overallScore,
      analysisJson: {
        'event': eventLabel,
        'stroke': stroke,
        'distance': distance,
        'course': course,
        'user_notes': notes,
        'disclaimer': disclaimer,
        'sections': sections,
        'usa_standards': usaStandards,
        'top_5_priorities': priorities,
        'personal_best_seconds': pb,
        'engine': 'swimiq-v1-notes',
      },
    );
  }

  List<String> _noteClauses(String notes) {
    if (notes.isEmpty) return const [];
    return notes
        .split(RegExp(r'[\n;]+'))
        .map((part) => part.replaceAll(RegExp(r'^[•\-\s]+'), '').trim())
        .where((part) => part.length > 2)
        .where((part) => !_isTemplateClause(part))
        .toList();
  }

  bool _isTemplateClause(String clause) {
    final lower = clause.toLowerCase();
    if (lower.startsWith('please analyze')) return true;
    if (lower.startsWith('provide:')) return true;
    if (lower.startsWith('athlete:')) return true;
    if (lower.startsWith('event:')) return true;
    if (lower == 'overall technique score (0–100)') return true;
    if (lower.contains('top 5 strengths')) return true;
    if (lower.contains('top 5 improvements')) return true;
    if (lower.contains('estimated time savings')) return true;
    if (lower.contains('drills to correct')) return true;
    return false;
  }

  List<String> _matchedClauses(List<String> clauses, List<String> keywords) {
    return clauses
        .where(
          (clause) => keywords.any(
            (keyword) => clause.toLowerCase().contains(keyword.toLowerCase()),
          ),
        )
        .toList();
  }

  String _formatSections(Map<String, String> sections) {
    return sections.entries
        .map((entry) => '${entry.key}\n${entry.value}')
        .join('\n\n');
  }

  List<String> _topPriorities({
    required String eventLabel,
    required List<String> clauses,
    required Map<String, String> sections,
  }) {
    final priorities = <String>[];

    void addUnique(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      if (!priorities.contains(trimmed) && priorities.length < 5) {
        priorities.add(trimmed);
      }
    }

    for (final clause in clauses) {
      addUnique('$clause ($eventLabel)');
    }

    return priorities.take(5).toList();
  }

  int _scoreFromNotes(
    String notes,
    int clauseCount,
    Map<String, String> sections,
  ) {
    if (notes.isEmpty) return 55;
    var score = 62;
    score += sections.length * 4;
    if (clauseCount >= 3) score += 6;
    if (clauseCount >= 6) score += 6;
    return score.clamp(55, 92);
  }

  String _usaStandardsSection({
    required String eventLabel,
    required String stroke,
    required int distance,
    required String course,
    required double? swimmerTime,
    required List<UsaTimeStandard> standards,
    SwimmerProfile? profile,
  }) {
    if (standards.isEmpty) {
      return 'Import USA Swimming motivational standards to compare $eventLabel.';
    }

    final ageGroup = SwimIqAgeGroup.fromProfile(profile);
    final relevant = standards
        .where(
          (standard) =>
              SwimStrokeUtils.matches(standard.stroke, stroke) &&
              standard.distance == distance &&
              standard.course == course &&
              standard.ageGroup == ageGroup,
        )
        .toList();

    if (relevant.isEmpty) {
      return 'No motivational standards found for $eventLabel ($ageGroup).';
    }

    const levelOrder = ['B', 'BB', 'A', 'AA', 'AAA', 'AAAA'];
    relevant.sort(
      (a, b) => levelOrder
          .indexOf(a.standardLevel)
          .compareTo(levelOrder.indexOf(b.standardLevel)),
    );

    final standardLines = relevant
        .map(
          (standard) =>
              '${standard.standardLevel}: ${SwimTime.fromSeconds(standard.timeSeconds)}',
        )
        .join('; ');

    if (swimmerTime == null) {
      return 'Motivational times for $eventLabel ($ageGroup): $standardLines. '
          'Log a time for this event to see which cut you are closest to.';
    }

    final achieved = _bestStandardMatch(
      standards: standards,
      stroke: stroke,
      distance: distance,
      course: course,
      swimmerTime: swimmerTime,
      profile: profile,
    );

    return 'Your best logged time for this event: ${SwimTime.fromSeconds(swimmerTime)}. '
        'Motivational times ($ageGroup): $standardLines. '
        '${achieved != null ? 'Highest cut currently achieved: $achieved.' : 'Keep pushing to reach the next motivational cut.'}';
  }

  String? _bestStandardMatch({
    required List<UsaTimeStandard> standards,
    required String stroke,
    required int distance,
    required String course,
    required double? swimmerTime,
    SwimmerProfile? profile,
  }) {
    if (swimmerTime == null || standards.isEmpty) return null;

    final ageGroup = SwimIqAgeGroup.fromProfile(profile);

    final matches = standards.where(
      (standard) =>
          SwimStrokeUtils.matches(standard.stroke, stroke) &&
          standard.distance == distance &&
          standard.course == course &&
          standard.ageGroup == ageGroup &&
          swimmerTime <= standard.timeSeconds,
    );

    if (matches.isEmpty) return null;

    const levelOrder = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];
    matches.toList().sort(
          (a, b) => levelOrder
              .indexOf(a.standardLevel)
              .compareTo(levelOrder.indexOf(b.standardLevel)),
        );
    final best = matches.first;
    return '${best.standardLevel} (${SwimTime.fromSeconds(best.timeSeconds)})';
  }
}
