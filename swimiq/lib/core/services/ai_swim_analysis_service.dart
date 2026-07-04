import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swim_time.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/usa_time_standard.dart';
import '../../data/models/video_models.dart';
import '../../data/models/swimmer_profile.dart';

/// V1 coaching report from video metadata, notes, and swimmer context.
class AiSwimAnalysisService {
  static const disclaimer =
      'V1 coaching analysis generated from video metadata and user notes. '
      'Frame-by-frame AI vision is not active yet.';

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

    final sections = <String, String>{
      'Reaction / dive': _reactionDive(ctx),
      'Streamline and underwater dolphin kicks': _underwater(ctx),
      'Breakout': _breakout(ctx),
      'Stroke length and stroke count': _strokeLength(ctx),
      'Tempo and rhythm': _tempo(ctx),
      'Breathing and head position': _breathing(ctx),
      'Finish': _finish(ctx),
      'USA Swimming standards comparison': _usaStandardsSection(ctx),
      'Recommended drills': _recommendedDrills(ctx, ctx.recommendedDrillList),
    };

    final priorities = _topPriorities(ctx);
    final techniqueScore = _techniqueScore(ctx, sections.length);
    final paceScore =
        ctx.personalBestSeconds != null ? (techniqueScore + 5).clamp(40, 95) : techniqueScore;
    final overallScore = ((techniqueScore + paceScore) / 2).round();

    final summary = StringBuffer()
      ..writeln('Event: ${ctx.eventLabel}')
      ..writeln(disclaimer)
      ..writeln(
        'Coaching report for ${ctx.distance} ${ctx.stroke} (${ctx.course}). '
        '${ctx.noteSignals.hasContent ? 'Interpretation is informed by your upload notes and logged swimmer data.' : 'Add upload notes to sharpen event-specific feedback.'}',
      );

    final improvements = StringBuffer('Top 5 priorities');
    if (priorities.isNotEmpty) {
      improvements.write('\n${priorities.map((p) => '• $p').join('\n')}');
    }

    return SwimVideoAnalysis(
      swimVideoId: video.id,
      swimmer: video.swimmer,
      summary: summary.toString().trim(),
      strengths: _formatSections(sections),
      improvements: improvements.toString().trim(),
      techniqueScore: techniqueScore,
      paceScore: paceScore,
      overallScore: overallScore,
      analysisJson: {
        'event': ctx.eventLabel,
        'stroke': ctx.stroke,
        'distance': ctx.distance,
        'course': ctx.course,
        'user_notes': ctx.notes,
        'disclaimer': disclaimer,
        'sections': sections,
        'top_5_priorities': priorities,
        'recommended_drills': ctx.recommendedDrillList,
        'personal_best_seconds': ctx.personalBestSeconds,
        'engine': 'swimiq-v1-notes',
      },
    );
  }

  String _reactionDive(_AnalysisContext ctx) {
    final sprint = ctx.isSprint;
    final reaction = ctx.noteSignals.reactionSeconds;
    String? insight;
    if (reaction != null) {
      final assessment = reaction <= 0.68
          ? 'That reaction is competitive for a sprint start'
          : reaction <= 0.75
              ? 'That reaction is workable but leaves room on the block'
              : 'That reaction suggests the start is costing early race momentum';
      insight =
          'You logged about ${reaction.toStringAsFixed(2)}s off the blocks — $assessment.';
    } else if (ctx.noteSignals.mentionsStart) {
      insight =
          'Your notes flag the start — verify block tension and reaction consistency across reps.';
    }

    return _sectionBody(
      lookFor:
          'Flat hips on the block, stable front foot, eyes down, explosive drive through the hands, and a clean angle of entry without excessive splash on ${ctx.eventLabel}.',
      impact:
          sprint
              ? 'On a ${ctx.distance} ${ctx.stroke}, start and underwater phases often decide the race; 0.05s lost here is hard to recover mid-pool.'
              : 'A slow or soft start compounds over ${ctx.distance}m — early velocity sets up underwater efficiency and stroke rhythm.',
      correction:
          'Film 5 block starts from the side: mark reaction time, entry distance, and whether the body stays in one line through the water.',
      noteInsight: insight,
    );
  }

  String _underwater(_AnalysisContext ctx) {
    final kicks = ctx.noteSignals.dolphinKickCount;
    final underwater = ctx.noteSignals.underwaterMeters;
    String? insight;
    if (kicks != null || underwater != null) {
      final kickPart =
          kicks != null ? '$kicks underwater dolphin kicks' : 'your underwater segment';
      final distPart =
          underwater != null ? ' before surfacing near ${underwater}m' : '';
      insight =
          'You noted $kickPart$distPart — compare kick amplitude and tempo to maintain speed without burning the legs early.';
    } else if (ctx.stroke == 'Butterfly' || ctx.stroke == 'Freestyle') {
      insight =
          'For ${ctx.eventLabel}, prioritize a tight streamline and rhythmic dolphin kicks (fly) or flutter kicks (free) before the first stroke.';
    }

    final kickGuidance = ctx.stroke == 'Butterfly'
        ? 'dolphin kick count, kick amplitude, and whether kicks stay within the body line'
        : ctx.stroke == 'Freestyle'
            ? 'streamline depth, kick tempo, and bubble trail staying narrow'
            : 'streamline extension and kick timing relative to breakout';

    return _sectionBody(
      lookFor:
          'Tight arms, one hand over the other, chin tucked, and consistent underwater propulsion — focus on $kickGuidance.',
      impact:
          'Underwater speed is free velocity; weak streamline or scattered kicks bleed time before stroke rhythm begins.',
      correction:
          ctx.stroke == 'Butterfly'
              ? 'Practice 4 x 15m underwater fly kick with a snorkel: count kicks to your target breakout mark and keep hips high.'
              : 'Hold streamline push-offs for 8–10m in practice, counting kicks until breakout feels fast, not frantic.',
      noteInsight: insight,
    );
  }

  String _breakout(_AnalysisContext ctx) {
    final breakoutM = ctx.noteSignals.breakoutMeters;
    String? insight;
    if (breakoutM != null) {
      final depth = breakoutM >= 12
          ? 'a relatively deep breakout'
          : breakoutM <= 8
              ? 'an early breakout'
              : 'a mid-range breakout distance';
      insight =
          'Surfacing around ${breakoutM}m is $depth for ${ctx.eventLabel} — check whether the first stroke accelerates or stalls after the breakout.';
    } else if (ctx.noteSignals.mentionsBreakout) {
      insight =
          'Your notes mention breakout timing — the first stroke should match underwater speed, not pause the rhythm.';
    }

    final firstStroke = ctx.stroke == 'Butterfly'
        ? 'first fly stroke lands with hips high and arms recovering without pausing'
        : 'first stroke cycle reuses underwater momentum without lifting the head';

    return _sectionBody(
      lookFor:
          'Smooth transition from kick to stroke: $firstStroke on ${ctx.eventLabel}.',
      impact:
          'A late, early, or sloppy breakout forces a speed drop that can cost 0.1–0.3s per length in sprint events.',
      correction:
          'Use lane markers: pick a target breakout point and rehearse the same kick count until the first stroke feels continuous.',
      noteInsight: insight,
    );
  }

  String _strokeLength(_AnalysisContext ctx) {
    final spl = ctx.noteSignals.strokeCountPerLength;
    String? insight;
    if (spl != null) {
      final range = ctx.expectedStrokeCountRange;
      final assessment = range == null
          ? 'validate whether that count matches your height and tempo goals'
          : spl > range.$2
              ? 'that count is on the high side — you may be spinning instead of gliding'
              : spl < range.$1
                  ? 'that count is low — confirm you are not over-gliding and losing tempo'
                  : 'that count sits in a reasonable range if tempo stays stable';
      insight =
          'You logged about $spl strokes per length — $assessment for ${ctx.eventLabel}.';
    } else if (ctx.noteSignals.mentionsStrokeCount) {
      insight =
          'Stroke count is noted — pair count with tempo: fewer, longer strokes only help if speed is maintained.';
    }

    return _sectionBody(
      lookFor:
          'Distance per stroke, catch completeness, and whether the body line stays long through ${ctx.stroke} on ${ctx.course}.',
      impact:
          'Short strokes increase turnover cost; over-gliding drops tempo. Balanced length supports sustainable speed over ${ctx.distance}m.',
      correction:
          'Swim 4 x 25 at moderate effort counting strokes; aim to remove one stroke per length without slowing average pace.',
      noteInsight: insight,
    );
  }

  String _tempo(_AnalysisContext ctx) {
    String? insight;
    if (ctx.noteSignals.tempoRushedLate == true) {
      insight =
          'Your notes describe tempo fading or rushing late — that pattern often follows breathing changes or shortened stroke length under fatigue.';
    } else if (ctx.noteSignals.mentionsTempo) {
      insight =
          'Tempo is flagged in your notes — compare early vs late 25 splits on video to see where cadence shifts.';
    }

    return _sectionBody(
      lookFor:
          'Stroke rate consistency from first stroke to finish, especially between the first and second halves of ${ctx.eventLabel}.',
      impact:
          'Tempo collapse late in the race is a common limiter; rushed short strokes add cycles without adding speed.',
      correction:
          'Swim 3 x (${ctx.isSprint ? '25' : '50'}) building pace: hold the same stroke count on each rep while slightly increasing speed.',
      noteInsight: insight,
    );
  }

  String _breathing(_AnalysisContext ctx) {
    String? insight;
    if (ctx.noteSignals.breathesEveryStroke == true) {
      insight =
          ctx.stroke == 'Butterfly' && ctx.isSprint
              ? 'Breathing every stroke on the second 25 of a 50 fly often costs rhythm — evaluate whether one fewer breath preserves tempo.'
              : 'Frequent breathing can lift the head and shorten stroke length; check hip drop on breath strokes.';
    } else if (ctx.noteSignals.mentionsBreathing) {
      insight =
          'Breathing pattern is noted — verify breath timing does not disrupt hip drive or arm recovery.';
    }

    final breathFocus = ctx.stroke == 'Butterfly'
        ? 'low forward breath with chin skimming the surface'
        : ctx.stroke == 'Freestyle'
            ? 'quick inhale with one goggle in the water and immediate return to neutral head'
            : 'head stability and breath timing relative to pull phase';

    return _sectionBody(
      lookFor:
          '$breathFocus on ${ctx.eventLabel}; head should not lift vertically before the breath.',
      impact:
          'Each exaggerated breath raises drag and can cut stroke length — in ${ctx.distance}m races this shows up as late-race fade.',
      correction:
          'Drill 6 x 25 with a fixed breath pattern; film from head-on to confirm eyes stay down between breaths.',
      noteInsight: insight,
    );
  }

  String _finish(_AnalysisContext ctx) {
    String? insight;
    if (ctx.noteSignals.finishExtensionMentioned == true) {
      insight =
          'You noted finish mechanics — confirm the last stroke drives into a full extension without an extra glide that slows touch velocity.';
    } else if (ctx.noteSignals.mentionsFinish) {
      insight =
          'Finish is mentioned in your notes — watch whether the swimmer maintains tempo into the wall or coasts early.';
    }

    return _sectionBody(
      lookFor:
          'Strong last stroke, hips toward the wall, full extension, and a clean touch without lifting the head on ${ctx.eventLabel}.',
      impact:
          'Finishes decide close races; decelerating 2–3m out can cost 0.1s+ on a ${ctx.distance} ${ctx.stroke}.',
      correction:
          'Practice finishes from the flags: 3 fast strokes into a full extension touch with eyes on the wall, not the clock.',
      noteInsight: insight,
    );
  }

  String _usaStandardsSection(_AnalysisContext ctx) {
    final standards = ctx.standards;
    final swimmerTime = ctx.personalBestSeconds;
    final eventLabel = ctx.eventLabel;
    final stroke = ctx.stroke;
    final distance = ctx.distance;
    final course = ctx.course;
    final profile = ctx.profile;

    if (standards.isEmpty) {
      return _sectionBody(
        lookFor:
            'How current race pace compares to age-group motivational cuts for $eventLabel once standards are imported.',
        impact:
            'Standards translate technique work into measurable time targets for training and meet selection.',
        correction:
            'Import USA Swimming motivational times, then log a recent $eventLabel result to anchor this comparison.',
        noteInsight: ctx.matchingGoal != null
            ? 'Goal on file: ${ctx.matchingGoal!.event} target ${SwimTime.fromSeconds(ctx.matchingGoal!.goalTime)}.'
            : null,
      );
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
      return _sectionBody(
        lookFor:
            'Whether logged times align with available motivational standards for $eventLabel ($ageGroup).',
        impact:
            'Without a standards match, progress is harder to benchmark against national age-group cuts.',
        correction:
            'Confirm stroke, distance, course, and age group metadata match the imported standards file.',
        noteInsight: null,
      );
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
      return _sectionBody(
        lookFor:
            'Which motivational cut is closest once a $eventLabel time is logged ($ageGroup: $standardLines).',
        impact:
            'Knowing the next cut focuses training on the time gap that matters for meets and goals.',
        correction:
            'Log a recent $eventLabel race or time trial to see which standard you are nearest.',
        noteInsight: ctx.matchingGoal != null
            ? 'Active goal: ${SwimTime.fromSeconds(ctx.matchingGoal!.goalTime)} by ${ctx.matchingGoal!.targetDate.toIso8601String().split('T').first}.'
            : null,
      );
    }

    final achieved = _bestStandardMatch(
      standards: standards,
      stroke: stroke,
      distance: distance,
      course: course,
      swimmerTime: swimmerTime,
      profile: profile,
    );
    final nextCut = _nextStandardTarget(
      standards: relevant,
      swimmerTime: swimmerTime,
    );

    return _sectionBody(
      lookFor:
          'Gap between best logged time ${SwimTime.fromSeconds(swimmerTime)} and motivational ladder ($ageGroup: $standardLines).',
      impact:
          achieved != null
              ? 'Achieving $achieved shows the speed is there — the next cut (${nextCut?.standardLevel ?? 'higher level'}) defines the training delta.'
              : 'Closing the gap to the next motivational cut quantifies how much race time must improve.',
      correction:
          nextCut != null
              ? 'Target ${nextCut.standardLevel} (${SwimTime.fromSeconds(nextCut.timeSeconds)}): close the ${(swimmerTime - nextCut.timeSeconds).toStringAsFixed(2)}s gap with start, underwater, and tempo work.'
              : 'Use standards times as repeat targets in practice sets to build race-specific pace awareness.',
      noteInsight: achieved != null
          ? 'Highest cut currently achieved: $achieved.'
          : 'No motivational cut achieved yet — nearest target is ${nextCut?.standardLevel ?? 'B'}.',
    );
  }

  List<String> _topPriorities(_AnalysisContext ctx) {
    final priorities = <String>[];

    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || priorities.contains(trimmed)) return;
      if (priorities.length < 5) priorities.add(trimmed);
    }

    if (ctx.noteSignals.reactionSeconds != null &&
        ctx.noteSignals.reactionSeconds! > 0.70) {
      add(
        'Sharpen block reaction and entry for ${ctx.eventLabel} — late starts are costly in ${ctx.distance}m races.',
      );
    }
    if (ctx.noteSignals.breakoutMeters != null &&
        ctx.noteSignals.breakoutMeters! < 9 &&
        (ctx.stroke == 'Butterfly' || ctx.stroke == 'Freestyle')) {
      add(
        'Extend underwater phase before breakout — early surface transition loses free speed.',
      );
    }
    if (ctx.noteSignals.strokeCountPerLength != null) {
      final range = ctx.expectedStrokeCountRange;
      final spl = ctx.noteSignals.strokeCountPerLength!;
      if (range != null && spl > range.$2) {
        add(
          'Reduce stroke count without losing tempo — high SPL often signals shortened catch.',
        );
      }
    }
    if (ctx.noteSignals.tempoRushedLate == true) {
      add(
        'Protect tempo in the last ${ctx.isSprint ? '15m' : 'length'} — avoid rushed short strokes under fatigue.',
      );
    }
    if (ctx.noteSignals.breathesEveryStroke == true &&
        ctx.stroke == 'Butterfly' &&
        ctx.isSprint) {
      add(
        'Experiment with one fewer breath on the second 25 to keep fly rhythm intact.',
      );
    }
    if (ctx.noteSignals.finishExtensionMentioned == false &&
        ctx.noteSignals.mentionsFinish) {
      add('Drive the last stroke into a full extension touch at the wall.');
    }
    if (ctx.personalBestSeconds != null && ctx.matchingGoal != null) {
      final gap = ctx.personalBestSeconds! - ctx.matchingGoal!.goalTime;
      if (gap > 0) {
        add(
          'Close ${gap.toStringAsFixed(2)}s to goal ${SwimTime.fromSeconds(ctx.matchingGoal!.goalTime)} on ${ctx.eventLabel}.',
        );
      }
    }
    if (ctx.matchingGoal != null && priorities.length < 5) {
      add(
        'Align weekly training sets with goal pace for ${ctx.matchingGoal!.event}.',
      );
    }

    add('Film side and head-on angles on the next ${ctx.eventLabel} upload.');
    add('Re-check start, breakout, and finish on every video review.');
    add('Track stroke count and tempo at the same effort level week to week.');

    return priorities.take(5).toList();
  }

  String _recommendedDrills(_AnalysisContext ctx, List<String> drills) {
    final drillLines = drills.map((d) => '• $d').join('\n');

    return _sectionBody(
      lookFor:
          'Whether drill work transfers to full-stroke ${ctx.eventLabel} — hips high, stable head, and consistent tempo.',
      impact:
          'Targeted drills isolate the limiter identified in start, underwater, breathing, or finish phases.',
      correction: drillLines,
      noteInsight: null,
    );
  }

  String _sectionBody({
    required String lookFor,
    required String impact,
    required String correction,
    String? noteInsight,
  }) {
    final buffer = StringBuffer()
      ..writeln('Look for: $lookFor')
      ..writeln('Performance impact: $impact')
      ..writeln('Correction: $correction');
    if (noteInsight != null && noteInsight.trim().isNotEmpty) {
      buffer.writeln('Note insight: $noteInsight');
    }
    return buffer.toString().trim();
  }

  String _formatSections(Map<String, String> sections) {
    return sections.entries
        .map((entry) => '${entry.key}\n${entry.value}')
        .join('\n\n');
  }

  int _techniqueScore(_AnalysisContext ctx, int sectionCount) {
    var score = 58;
    if (ctx.noteSignals.hasContent) score += 8;
    if (ctx.noteSignals.reactionSeconds != null) score += 4;
    if (ctx.noteSignals.strokeCountPerLength != null) score += 4;
    if (ctx.personalBestSeconds != null) score += 6;
    if (ctx.matchingGoal != null) score += 4;
    if (sectionCount >= 8) score += 4;
    return score.clamp(55, 92);
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
    final sorted = matches.toList()
      ..sort(
        (a, b) => levelOrder
            .indexOf(a.standardLevel)
            .compareTo(levelOrder.indexOf(b.standardLevel)),
      );
    final best = sorted.first;
    return '${best.standardLevel} (${SwimTime.fromSeconds(best.timeSeconds)})';
  }

  UsaTimeStandard? _nextStandardTarget({
    required List<UsaTimeStandard> standards,
    required double swimmerTime,
  }) {
    const levelOrder = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];
    final faster = standards
        .where((standard) => swimmerTime > standard.timeSeconds)
        .toList();
    if (faster.isEmpty) return null;
    faster.sort(
      (a, b) => levelOrder
          .indexOf(b.standardLevel)
          .compareTo(levelOrder.indexOf(a.standardLevel)),
    );
    return faster.first;
  }
}

class _NoteSignals {
  const _NoteSignals({
    this.reactionSeconds,
    this.breakoutMeters,
    this.dolphinKickCount,
    this.underwaterMeters,
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
  final int? underwaterMeters;
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

    final reactionMatch =
        RegExp(r'reaction(?:\s*time)?\s*(?:of|at|:)?\s*(\d+\.\d+)', caseSensitive: false)
            .firstMatch(notes);
    final breakoutMatch =
        RegExp(r'breakout(?:\s*at)?\s*(\d+)\s*m', caseSensitive: false)
            .firstMatch(notes);
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
      underwaterMeters: breakoutMatch != null
          ? int.tryParse(breakoutMatch.group(1)!)
          : null,
      strokeCountPerLength: strokeCountMatch != null
          ? int.tryParse(
              strokeCountMatch.group(1) ?? strokeCountMatch.group(2) ?? '',
            )
          : null,
      breathesEveryStroke: lower.contains('breath')
          ? lower.contains('every stroke')
          : null,
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
      mentionsTempo:
          lower.contains('tempo') || lower.contains('rhythm') || lower.contains('cadence'),
      mentionsBreathing: lower.contains('breath'),
      mentionsFinish:
          lower.contains('finish') || lower.contains('touch') || lower.contains('wall'),
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
    required this.recommendedDrillList,
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
  final List<String> recommendedDrillList;

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

    final base = _AnalysisContext(
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
      recommendedDrillList: const [],
    );

    return _AnalysisContext(
      eventLabel: base.eventLabel,
      stroke: base.stroke,
      distance: base.distance,
      course: base.course,
      notes: base.notes,
      noteSignals: base.noteSignals,
      personalBestSeconds: base.personalBestSeconds,
      matchingGoal: base.matchingGoal,
      standards: base.standards,
      profile: base.profile,
      recommendedDrillList: _buildRecommendedDrills(base),
    );
  }
}

List<String> _buildRecommendedDrills(_AnalysisContext ctx) {
  final drills = <String>[];

  if (ctx.stroke == 'Butterfly') {
    drills.addAll([
      '3-3-3 fly drill (3 right arm, 3 left arm, 3 full strokes)',
      'Underwater dolphin kick on streamline to target breakout mark',
      'Single-arm fly with low forward breath',
    ]);
  } else if (ctx.stroke == 'Freestyle') {
    drills.addAll([
      'Catch-up freestyle with fingertip drag',
      '6-kick switch with eyes down',
      'Underwater streamline kick sets to breakout',
    ]);
  } else if (ctx.stroke == 'Backstroke') {
    drills.addAll([
      'Single-arm back with stable head',
      'Backstroke spin drill for tempo awareness',
      'Underwater dolphin kick off backstroke flags',
    ]);
  } else if (ctx.stroke == 'Breaststroke') {
    drills.addAll([
      '2-kick 1-pull breast for timing',
      'Breaststroke pullout rehearsal from push-off',
      'Short-axis glide drill with narrow kick',
    ]);
  } else {
    drills.add('Technique-focused drill sets matched to primary stroke');
  }

  if (ctx.noteSignals.reactionSeconds != null &&
      ctx.noteSignals.reactionSeconds! > 0.70) {
    drills.add('Block start rehearsal with reaction-time calls');
  }
  if (ctx.noteSignals.tempoRushedLate == true) {
    drills.add('Descend 4 x 25 holding stroke count constant');
  }
  if (ctx.noteSignals.breathesEveryStroke == true) {
    drills.add('Breath-pattern 25s with head-on video check');
  }
  if (ctx.noteSignals.mentionsFinish || ctx.isSprint) {
    drills.add('Finish sprints from the flags (3 strokes to wall)');
  }

  return drills.take(5).toList();
}
