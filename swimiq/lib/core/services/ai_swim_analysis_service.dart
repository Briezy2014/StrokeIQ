import '../../core/utils/swim_time.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/usa_time_standard.dart';
import '../../data/models/video_models.dart';
import '../../data/models/swimmer_profile.dart';

/// Notes-driven V1 coaching analysis. Replace with frame-by-frame ML later.
class AiSwimAnalysisService {
  static const disclaimer =
      'V1 coaching analysis based on video metadata and user notes, '
      'not automated frame-by-frame computer vision yet.';

  SwimVideoAnalysis analyze({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
    List<UsaTimeStandard> standards = const [],
  }) {
    final eventLabel = video.eventLabel;
    final stroke = video.stroke ?? profile?.primaryStroke ?? 'Freestyle';
    final distance = video.distanceMeters ?? 100;
    final course = video.course ?? 'SCY';
    final notes = video.notes?.trim() ?? '';
    final clauses = _noteClauses(notes);

    final matchingLogs = raceLogs.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == course,
    );
    final pb = matchingLogs.isEmpty
        ? null
        : matchingLogs
            .map((log) => log.timeSeconds)
            .reduce((a, b) => a < b ? a : b);

    final sections = <String, String>{
      'Reaction / dive': _sectionFeedback(
        eventLabel: eventLabel,
        clauses: clauses,
        notes: notes,
        keywords: const [
          'reaction',
          'dive',
          'start',
          'block',
          'entry',
          'explosive',
        ],
        strokeHint:
            'Focus on block setup, reaction timing, and clean angle into the water.',
      ),
      'Streamline and underwater dolphin kicks': _sectionFeedback(
        eventLabel: eventLabel,
        clauses: clauses,
        notes: notes,
        keywords: const [
          'streamline',
          'underwater',
          'dolphin',
          'kick',
          'uw',
          'under water',
          'fly kick',
        ],
        strokeHint: stroke == 'Butterfly'
            ? 'Prioritize tight streamline and rhythmic underwater dolphin kicks before surfacing.'
            : 'Prioritize tight streamline and legal underwater propulsion off each wall.',
      ),
      'Breakout': _sectionFeedback(
        eventLabel: eventLabel,
        clauses: clauses,
        notes: notes,
        keywords: const [
          'breakout',
          'surface',
          'first stroke',
          'break out',
          'pop up',
        ],
        strokeHint: stroke == 'Butterfly'
            ? 'Time the first fly stroke so the breakout is smooth without losing momentum.'
            : 'Surface with the first effective stroke without excessive deceleration.',
      ),
      'Stroke length and tempo': _sectionFeedback(
        eventLabel: eventLabel,
        clauses: clauses,
        notes: notes,
        keywords: const [
          'tempo',
          'stroke count',
          'stroke length',
          'rhythm',
          'cadence',
          'cycles',
          'rate',
        ],
        strokeHint: stroke == 'Butterfly'
            ? 'Balance fly tempo with distance per stroke — short course rewards controlled power.'
            : 'Match stroke length to tempo for efficient speed through the race.',
      ),
      'Body position and breathing': _sectionFeedback(
        eventLabel: eventLabel,
        clauses: clauses,
        notes: notes,
        keywords: const [
          'breath',
          'breathing',
          'body position',
          'hips',
          'head',
          'posture',
          'alignment',
        ],
        strokeHint: stroke == 'Butterfly'
            ? 'Keep hips high, head neutral, and breathing low/forward to protect rhythm.'
            : 'Maintain stable body line and efficient breathing pattern for the event.',
      ),
      'Finish': _sectionFeedback(
        eventLabel: eventLabel,
        clauses: clauses,
        notes: notes,
        keywords: const [
          'finish',
          'touch',
          'wall',
          'glide',
          'final',
          'lunge',
        ],
        strokeHint: 'Drive through the wall with full extension and no early deceleration.',
      ),
    };

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
      notes: notes,
      clauses: clauses,
      stroke: stroke,
      sections: sections,
      hasPb: pb != null,
      hasGoal: goals.any(
        (goal) =>
            goal.event.contains('$distance') && goal.event.contains(stroke),
      ),
    );

    final techniqueScore = _scoreFromNotes(notes, clauses.length, sections);
    final paceScore = pb != null ? (techniqueScore + 5).clamp(40, 95) : techniqueScore;
    final overallScore = ((techniqueScore + paceScore) / 2).round();

    final summary = StringBuffer()
      ..writeln('Event: $eventLabel')
      ..writeln(disclaimer);
    if (notes.isNotEmpty) {
      summary.writeln('Your notes: $notes');
    } else {
      summary.writeln(
        'Add stroke-specific notes on the upload form for more targeted section feedback.',
      );
    }

    final strengths = _formatSections(sections);
    final improvements = StringBuffer()
      ..writeln('USA Swimming motivational standards comparison')
      ..writeln(usaStandards)
      ..writeln()
      ..writeln('Top 5 priorities')
      ..write(priorities.map((p) => '• $p').join('\n'));

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
        .split(RegExp(r'[.\n;]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  String _sectionFeedback({
    required String eventLabel,
    required List<String> clauses,
    required String notes,
    required List<String> keywords,
    required String strokeHint,
  }) {
    final matched = clauses
        .where(
          (clause) => keywords.any(
            (keyword) => clause.toLowerCase().contains(keyword.toLowerCase()),
          ),
        )
        .toList();

    if (matched.isNotEmpty) {
      return 'For $eventLabel, your notes highlight this area: ${matched.join('; ')}. '
          'Coaching focus: $strokeHint';
    }

    if (notes.isNotEmpty) {
      return 'For $eventLabel, apply your notes ("$notes") while reviewing this area. '
          'Coaching focus: $strokeHint';
    }

    return 'For $eventLabel: $strokeHint Add notes on this area for more specific feedback.';
  }

  String _formatSections(Map<String, String> sections) {
    return sections.entries.map((entry) => '${entry.key}\n${entry.value}').join('\n\n');
  }

  List<String> _topPriorities({
    required String eventLabel,
    required String notes,
    required List<String> clauses,
    required String stroke,
    required Map<String, String> sections,
    required bool hasPb,
    required bool hasGoal,
  }) {
    final priorities = <String>[];

    void addUnique(String value) {
      if (!priorities.contains(value) && priorities.length < 5) {
        priorities.add(value);
      }
    }

    for (final clause in clauses) {
      addUnique('Address in training: $clause ($eventLabel).');
    }

    if (notes.toLowerCase().contains('reaction')) {
      addUnique('Drill reaction starts and block timing for $eventLabel.');
    }
    if (stroke == 'Butterfly' &&
        (notes.toLowerCase().contains('underwater') ||
            notes.toLowerCase().contains('dolphin'))) {
      addUnique('Set a consistent underwater dolphin kick count for $eventLabel.');
    }
    if (notes.toLowerCase().contains('breakout')) {
      addUnique('Practice breakout timing so the first stroke connects to underwater speed.');
    }
    if (notes.toLowerCase().contains('tempo') ||
        notes.toLowerCase().contains('stroke')) {
      addUnique('Film side view and count strokes per length to tune tempo for $eventLabel.');
    }
    if (notes.toLowerCase().contains('finish')) {
      addUnique('Finish drills: full extension into the wall without slowing early.');
    }

    if (stroke == 'Butterfly') {
      addUnique('Keep breathing low and forward to protect fly rhythm in $eventLabel.');
      addUnique('Maintain hip height through the full 50 — avoid sinking on the second 25.');
    }

    if (!hasPb) {
      addUnique('Log a race or time trial result for $eventLabel to unlock USA time comparisons.');
    }
    if (!hasGoal) {
      addUnique('Set a goal time for $eventLabel to track progress against standards.');
    }

    if (priorities.length < 5) {
      addUnique('Re-watch this video with your coach and tag timestamps in the notes field.');
    }
    if (priorities.length < 5) {
      addUnique(
        'Film underwater and side angles on the next upload for richer section feedback.',
      );
    }

    return priorities.take(5).toList();
  }

  int _scoreFromNotes(
    String notes,
    int clauseCount,
    Map<String, String> sections,
  ) {
    var score = 62;
    if (notes.isNotEmpty) score += 8;
    if (clauseCount >= 2) score += 6;
    if (clauseCount >= 4) score += 4;
    final keywordHits = sections.values
        .where((section) => section.contains('your notes highlight'))
        .length;
    score += keywordHits * 3;
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
              standard.stroke == stroke &&
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

    final gender = _inferGender(profile);
    final ageGroup = SwimIqAgeGroup.fromProfile(profile);

    final matches = standards.where(
      (standard) =>
          standard.stroke == stroke &&
          standard.distance == distance &&
          standard.course == course &&
          (gender == null || standard.gender == gender) &&
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

  String? _inferGender(SwimmerProfile? profile) => null;
}
