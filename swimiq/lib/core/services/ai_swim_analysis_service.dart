import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/usa_time_standard.dart';
import '../../data/models/video_models.dart';
import '../../data/models/swimmer_profile.dart';

/// Local fallback when Gemini edge analysis is unavailable.
class AiSwimAnalysisService {
  static const disclaimer =
      'Notes-based coaching — Elite AI uses Gemini and MediaPipe for frame-by-frame video read.';

  SwimVideoAnalysis analyze({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
    List<UsaTimeStandard> standards = const [],
  }) {
    final ctx = _AnalysisContext.build(
      video: video,
      raceLogs: raceLogs,
      goals: goals,
      profile: profile,
      standards: standards,
    );

    final suggestions = _whatVideoSuggests(ctx);
    final priorities = _topThreePriorities(ctx);
    final timeSavings = _estimatedTimeSavings(ctx);
    final coachNotes = _coachNotesForNextRace(ctx, priorities);
    final quickPro = _quickPro(ctx, suggestions);
    final quickCon = _quickCon(ctx, suggestions);
    final nextRaceGoal = _nextRaceGoal(ctx, priorities);
    final dryland = _drylandFocus(ctx);

    final sections = <String, String>{
      'Quick pro from this video': quickPro,
      'Quick con from this video': quickCon,
      'Goal for your next race': nextRaceGoal,
      'Top 3 priorities for your next race': _bulletBlock(priorities),
      'Dryland focus (strength · mobility · stability)': dryland,
      'Estimated time savings': timeSavings,
      'Coach notes for next race': coachNotes,
    };

    final overallScore = _overallScore(ctx, suggestions.length);

    return SwimVideoAnalysis(
      swimVideoId: video.id,
      swimmer: video.swimmer,
      summary: '${ctx.eventLabel}\n$quickPro\n$quickCon',
      strengths: _formatSections(sections),
      improvements: 'Top 3 priorities for your next race\n'
          '${_bulletBlock(priorities)}',
      techniqueScore: overallScore,
      paceScore: overallScore,
      overallScore: overallScore,
      analysisJson: {
        'event': ctx.eventLabel,
        'stroke': ctx.stroke,
        'distance': ctx.distance,
        'course': ctx.course,
        'user_notes': ctx.notes,
        'disclaimer': disclaimer,
        'sections': sections,
        'top_3_priorities': priorities,
        'estimated_time_savings': timeSavings,
        'coach_notes_for_next_race': coachNotes,
        'quick_pro': quickPro,
        'quick_con': quickCon,
        'next_race_goal': nextRaceGoal,
        'dryland_focus': dryland,
        'personal_best_seconds': ctx.personalBestSeconds,
        'engine': 'swimiq-v1-notes',
      },
    );
  }


  List<String> _whatVideoSuggests(_AnalysisContext ctx) {
    final items = <String>[];
    final s = ctx.noteSignals;
    final event = ctx.eventLabel;

    if (s.reactionSeconds != null) {
      final rt = s.reactionSeconds!;
      final tag = rt <= 0.68
          ? 'a solid start to build on'
          : rt <= 0.75
              ? 'room to sharpen the block reaction'
              : 'the start may be costing early speed';
      items.add(
        'Notes cite ~${rt.toStringAsFixed(2)}s reaction — for $event that is $tag.',
      );
    } else if (s.mentionsStart) {
      items.add('Start phase is flagged in your notes for $event.');
    }

    if (s.breakoutMeters != null) {
      items.add(
        'Breakout around ${s.breakoutMeters}m is noted'
        '${s.dolphinKickCount != null ? ' after ${s.dolphinKickCount} underwater kicks' : ''} — '
        'check whether the first stroke keeps underwater speed.',
      );
    } else if (s.dolphinKickCount != null) {
      items.add(
        '${s.dolphinKickCount} underwater kicks logged — compare kick tempo to breakout timing.',
      );
    }

    if (s.strokeCountPerLength != null) {
      final spl = s.strokeCountPerLength!;
      final range = ctx.expectedStrokeCountRange;
      final note = range == null
          ? 'validate against pace'
          : spl > range.$2
              ? 'on the high side for $event'
              : spl < range.$1
                  ? 'on the low side — watch for over-gliding'
                  : 'in a reasonable range if tempo holds';
      items.add('~$spl strokes per length noted — $note.');
    }

    if (s.breathesEveryStroke == true && ctx.stroke == 'Butterfly' && ctx.isSprint) {
      items.add(
        'Breathing every stroke on the second 25 may disrupt fly rhythm on a 50.',
      );
    } else if (s.mentionsBreathing) {
      items.add('Breathing pattern is noted — watch for head lift slowing the hips.');
    }

    if (s.tempoRushedLate == true) {
      items.add('Tempo fades or rushes late in the race — common limiter on $event.');
    }

    if (s.finishExtensionMentioned == true) {
      items.add('Finish extension is noted — confirm the last stroke drives to the wall.');
    } else if (s.mentionsFinish) {
      items.add('Finish phase is flagged — avoid coasting in the last few meters.');
    }

    if (items.isEmpty && ctx.notes.isNotEmpty) {
      items.add(
        'Your notes mention race details for $event — re-run after adding start, stroke count, or finish specifics.',
      );
    }

    if (items.isEmpty) {
      items.add('No upload notes yet — the app cannot infer technique from the file alone.');
    }

    return items.take(5).toList();
  }

  String _quickPro(_AnalysisContext ctx, List<String> suggestions) {
    if (suggestions.isEmpty) {
      return '• Upload notes with start, stroke count, and finish details to unlock a specific pro.';
    }
    return '• ${suggestions.first}';
  }

  String _quickCon(_AnalysisContext ctx, List<String> suggestions) {
    final s = ctx.noteSignals;
    if (s.reactionSeconds != null && s.reactionSeconds! > 0.70) {
      return '• Reaction time looks slow — early speed is leaking off the blocks.';
    }
    if (s.tempoRushedLate == true) {
      return '• Late-race tempo fades — length and rhythm drop when it matters most.';
    }
    if (s.breathesEveryStroke == true && ctx.isSprint) {
      return '• Breathing pattern may be costing rhythm on a sprint ${ctx.eventLabel}.';
    }
    if (suggestions.length > 1) {
      return '• ${suggestions[1]}';
    }
    return '• Add side + head-on video next time for sharper feedback on body line.';
  }

  String _nextRaceGoal(_AnalysisContext ctx, List<String> priorities) {
    if (ctx.matchingGoal != null) {
      return 'Race ${ctx.eventLabel} at '
          '${SwimTime.fromSeconds(ctx.matchingGoal!.goalTime)} or faster.';
    }
    if (ctx.personalBestSeconds != null) {
      final target = ctx.personalBestSeconds! - 0.5;
      return 'Drop ${ctx.eventLabel} toward '
          '${SwimTime.fromSeconds(target > 0 ? target : ctx.personalBestSeconds!)} '
          'on your next meet.';
    }
    if (priorities.isNotEmpty) {
      return 'Carry “${priorities.first}” into your next ${ctx.eventLabel} race.';
    }
    return 'Set a goal time for ${ctx.eventLabel} in Goals, then race it.';
  }

  String _drylandFocus(_AnalysisContext ctx) {
    final stroke = ctx.stroke;
    final lines = switch (stroke) {
      'Butterfly' => [
        '3 x 20 sec dolphin kick on the floor — drive from hips, not knees.',
        '2 x 10 supermans — long body line, thumbs up, squeeze glutes.',
        '2 x 15 band pull-aparts — stable shoulders for a high-elbow catch.',
        '3 x 30 sec hollow hold — core stays tight when breathing lifts the head.',
      ],
      'Backstroke' => [
        '2 x 10 shoulder dislocates with band — smooth rotation without pinching.',
        '3 x 30 sec side plank each side — hips stay level through rotation.',
        '2 x 12 glute bridges — strong kick initiation off the wall.',
        '10 arm circles + 10 cross-body swings — loose shoulders before racing.',
      ],
      'Breaststroke' => [
        '2 x 10 wall angels — mobility for a clean narrow kick recovery.',
        '3 x 12 squat-to-stand with pause — leg drive without losing posture.',
        '2 x 30 sec forearm plank — stable chest through the pull phase.',
        '10 hip openers each leg — keep knees tracking on the kick.',
      ],
      _ => [
        '3 x 30 sec forearm plank — flat body line under fatigue.',
        '2 x 12 single-leg glute bridges each side — hip drive for kick power.',
        '2 x 15 band external rotations — protect shoulders on high-volume free.',
        '10 cross-body arm swings + 10 leg swings — race-day mobility primer.',
      ],
    };
    return lines.map((line) => '• $line').join('\n');
  }

  List<String> _topThreePriorities(_AnalysisContext ctx) {
    final items = <String>[];

    void add(String value) {
      if (items.length < 3 && !items.contains(value)) items.add(value);
    }

    final s = ctx.noteSignals;
    final event = ctx.eventLabel;

    if (s.reactionSeconds != null && s.reactionSeconds! > 0.70) {
      add('Tighten block setup and reaction for $event.');
    }
    if (s.breakoutMeters != null &&
        s.breakoutMeters! < 9 &&
        (ctx.stroke == 'Butterfly' || ctx.stroke == 'Freestyle')) {
      add('Hold streamline longer before breakout.');
    }
    if (s.strokeCountPerLength != null) {
      final range = ctx.expectedStrokeCountRange;
      final spl = s.strokeCountPerLength!;
      if (range != null && spl > range.$2) {
        add('Lower stroke count without losing tempo.');
      } else if (range != null && spl < range.$1) {
        add('Add rhythm — avoid over-gliding between strokes.');
      }
    }
    if (s.tempoRushedLate == true) {
      add('Keep stroke length stable in the last ${ctx.isSprint ? '15m' : 'length'}.');
    }
    if (s.breathesEveryStroke == true &&
        ctx.stroke == 'Butterfly' &&
        ctx.isSprint) {
      add('Test one fewer breath on the second 25 in your next race.');
    }
    if (s.mentionsFinish || ctx.isSprint) {
      add('Drive full extension on the last stroke at the wall.');
    }
    if (ctx.personalBestSeconds != null && ctx.matchingGoal != null) {
      final gap = ctx.personalBestSeconds! - ctx.matchingGoal!.goalTime;
      if (gap > 0) {
        add(
          'Close ${gap.toStringAsFixed(2)}s to goal '
          '${SwimTime.fromSeconds(ctx.matchingGoal!.goalTime)} at the next meet.',
        );
      }
    }
    if (s.reactionSeconds != null && s.reactionSeconds! <= 0.68) {
      add('Keep the same block routine — reaction is already a strength.');
    }
    if (items.length < 3) {
      add('Hold tempo and body line through the last ${ctx.isSprint ? '15m' : 'length'}.');
    }
    if (items.length < 3) {
      add('Race with a clear breakout kick count and first-stroke plan.');
    }

    return items.take(3).toList();
  }

  String _estimatedTimeSavings(_AnalysisContext ctx) {
    final s = ctx.noteSignals;
    final lines = <String>[];

    if (s.reactionSeconds != null && s.reactionSeconds! > 0.70) {
      lines.add('Sharper start: often 0.05–0.15s on a ${ctx.distance}m race');
    }
    if (s.breakoutMeters != null && s.breakoutMeters! < 10) {
      lines.add('Better underwater phase: ~0.1–0.2s per length (estimate)');
    }
    if (s.strokeCountPerLength != null) {
      final range = ctx.expectedStrokeCountRange;
      final spl = s.strokeCountPerLength!;
      if (range != null && spl > range.$2) {
        lines.add('One fewer stroke per length: ~0.1–0.3s per 25 (estimate)');
      }
    }
    if (s.tempoRushedLate == true) {
      lines.add('Stable late-race tempo: ~0.1–0.2s on a sprint (estimate)');
    }
    if (s.breathesEveryStroke == true && ctx.isSprint) {
      lines.add('One fewer breath on a 50: ~0.05–0.15s (estimate)');
    }

    if (lines.isEmpty) {
      return 'Add detailed upload notes to estimate where time is most likely hiding. '
          'These ranges are coaching estimates, not measured from video.';
    }

    final totalLow = lines.length * 0.05;
    final totalHigh = lines.length * 0.15;
    return '${_bulletBlock(lines)}\n\n'
        'Rough combined range if priorities improve: '
        '${totalLow.toStringAsFixed(2)}–${totalHigh.toStringAsFixed(2)}s '
        '(estimates only — not measured from this upload).';
  }

  String _coachNotesForNextRace(_AnalysisContext ctx, List<String> priorities) {
    final lines = <String>[
      'Event: ${ctx.eventLabel}',
      'Pre-race: confirm block settings and breakout kick count plan',
    ];

    if (ctx.noteSignals.reactionSeconds != null) {
      lines.add(
        'Target reaction: low-${(ctx.noteSignals.reactionSeconds! - 0.03).clamp(0.55, 0.99).toStringAsFixed(2)}s range',
      );
    }
    if (ctx.noteSignals.strokeCountPerLength != null) {
      lines.add(
        'Stroke-count target: ~${ctx.noteSignals.strokeCountPerLength} per length',
      );
    }
    if (priorities.isNotEmpty) {
      lines.add('Race focus: ${priorities.first}');
    }
    if (ctx.personalBestSeconds != null) {
      lines.add('PB reference: ${SwimTime.fromSeconds(ctx.personalBestSeconds!)}');
    }

    return _bulletBlock(lines);
  }

  String _bulletBlock(List<String> items) =>
      items.map((item) => '• $item').join('\n');

  String _formatSections(Map<String, String> sections) {
    return sections.entries
        .map((entry) => '${entry.key}\n${entry.value}')
        .join('\n\n');
  }

  int _overallScore(_AnalysisContext ctx, int suggestionCount) {
    var score = 60;
    if (ctx.noteSignals.hasContent) score += 10;
    if (suggestionCount >= 3) score += 8;
    if (ctx.personalBestSeconds != null) score += 6;
    if (ctx.matchingGoal != null) score += 4;
    return score.clamp(55, 88);
  }
}

class _NoteSignals {
  const _NoteSignals({
    this.reactionSeconds,
    this.breakoutMeters,
    this.dolphinKickCount,
    this.strokeCountPerLength,
    this.breathesEveryStroke,
    this.tempoRushedLate,
    this.finishExtensionMentioned,
    this.mentionsStart = false,
    this.mentionsBreakout = false,
    this.mentionsStrokeCount = false,
    this.mentionsTempo = false,
    this.mentionsBreathing = false,
    this.mentionsFinish = false,
  });

  final double? reactionSeconds;
  final int? breakoutMeters;
  final int? dolphinKickCount;
  final int? strokeCountPerLength;
  final bool? breathesEveryStroke;
  final bool? tempoRushedLate;
  final bool? finishExtensionMentioned;
  final bool mentionsStart;
  final bool mentionsBreakout;
  final bool mentionsStrokeCount;
  final bool mentionsTempo;
  final bool mentionsBreathing;
  final bool mentionsFinish;

  bool get hasContent =>
      reactionSeconds != null ||
      breakoutMeters != null ||
      dolphinKickCount != null ||
      strokeCountPerLength != null ||
      breathesEveryStroke != null ||
      tempoRushedLate == true ||
      mentionsStart ||
      mentionsBreakout ||
      mentionsStrokeCount ||
      mentionsTempo ||
      mentionsBreathing ||
      mentionsFinish;

  static _NoteSignals parse(String notes) {
    final lower = notes.toLowerCase();
    if (notes.trim().isEmpty) return const _NoteSignals();

    final reactionMatch = RegExp(
      r'reaction(?:\s*time)?\s*(?:of|at|:)?\s*(\d+\.\d+)',
      caseSensitive: false,
    ).firstMatch(notes);
    final breakoutMatch = RegExp(
      r'breakout(?:\s*at)?\s*(\d+)\s*m',
      caseSensitive: false,
    ).firstMatch(notes);
    final kickMatch =
        RegExp(r'(\d+)\s*dolphin', caseSensitive: false).firstMatch(notes);
    final strokeCountMatch = RegExp(
      r'stroke count\s*(\d+)|(\d+)\s*(?:per length|spl|strokes per)',
      caseSensitive: false,
    ).firstMatch(notes);

    return _NoteSignals(
      reactionSeconds: reactionMatch != null
          ? double.tryParse(reactionMatch.group(1)!)
          : null,
      breakoutMeters:
          breakoutMatch != null ? int.tryParse(breakoutMatch.group(1)!) : null,
      dolphinKickCount:
          kickMatch != null ? int.tryParse(kickMatch.group(1)!) : null,
      strokeCountPerLength: strokeCountMatch != null
          ? int.tryParse(
              strokeCountMatch.group(1) ?? strokeCountMatch.group(2) ?? '',
            )
          : null,
      breathesEveryStroke:
          lower.contains('breath') ? lower.contains('every stroke') : null,
      tempoRushedLate: lower.contains('tempo') &&
          (lower.contains('rush') ||
              lower.contains('last 15') ||
              lower.contains('fade')),
      finishExtensionMentioned: lower.contains('finish') &&
          (lower.contains('extension') || lower.contains('full extension')),
      mentionsStart: lower.contains('reaction') ||
          lower.contains('dive') ||
          lower.contains('block') ||
          lower.contains('start'),
      mentionsBreakout: lower.contains('breakout') || lower.contains('surface'),
      mentionsStrokeCount:
          lower.contains('stroke count') || lower.contains('spl'),
      mentionsTempo: lower.contains('tempo') ||
          lower.contains('rhythm') ||
          lower.contains('cadence'),
      mentionsBreathing: lower.contains('breath'),
      mentionsFinish: lower.contains('finish') ||
          lower.contains('touch') ||
          lower.contains('wall'),
    );
  }
}

class _AnalysisContext {
  _AnalysisContext({
    required this.eventLabel,
    required this.stroke,
    required this.distance,
    required this.course,
    required this.notes,
    required this.noteSignals,
    required this.personalBestSeconds,
    required this.matchingGoal,
    required this.standards,
    required this.profile,
  });

  final String eventLabel;
  final String stroke;
  final int distance;
  final String course;
  final String notes;
  final _NoteSignals noteSignals;
  final double? personalBestSeconds;
  final SwimGoal? matchingGoal;
  final List<UsaTimeStandard> standards;
  final SwimmerProfile? profile;

  bool get isSprint => distance <= 50;

  (int, int)? get expectedStrokeCountRange {
    if (stroke == 'Butterfly') {
      return course == 'LCM' ? (15, 19) : (14, 18);
    }
    if (stroke == 'Freestyle') {
      return course == 'LCM' ? (14, 18) : (12, 16);
    }
    return null;
  }

  factory _AnalysisContext.build({
    required SwimVideo video,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    SwimmerProfile? profile,
    required List<UsaTimeStandard> standards,
  }) {
    final stroke = SwimStrokeUtils.canonical(
      video.stroke ?? profile?.primaryStroke ?? 'Freestyle',
    );
    final distance = video.distanceMeters ?? 100;
    final course = video.course ?? 'SCY';
    final notes = video.notes?.trim() ?? '';
    final noteSignals = _NoteSignals.parse(notes);

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

    SwimGoal? matchingGoal;
    for (final goal in goals) {
      final goalStroke = SwimStrokeUtils.canonical(goal.event);
      if (goal.course == course &&
          (goalStroke == stroke || goal.event.contains('$distance'))) {
        matchingGoal = goal;
        break;
      }
    }

    return _AnalysisContext(
      eventLabel: video.eventLabel,
      stroke: stroke,
      distance: distance,
      course: course,
      notes: notes,
      noteSignals: noteSignals,
      personalBestSeconds: pb,
      matchingGoal: matchingGoal,
      standards: standards,
      profile: profile,
    );
  }
}
