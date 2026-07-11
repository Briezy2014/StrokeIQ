import '../../data/models/swim_pose_metrics.dart';
import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swim_time.dart';
import '../../core/utils/youth_coaching_phrases.dart';
import '../../core/utils/youth_friendly_analysis.dart';
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
    SwimPoseMetrics? poseMetrics,
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
    final timeSavings = _estimatedTimeSavings(ctx, poseMetrics);
    final coachNotes = _coachNotesForNextRace(ctx, priorities, poseMetrics);
    final quickPro = _quickPro(ctx, poseMetrics);
    final quickCon = _quickCon(ctx, suggestions, poseMetrics);
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

    final techniqueScore = _techniqueScore(ctx, suggestions, poseMetrics);
    final paceScore = _paceScore(ctx);
    final overallScore = _overallScore(ctx, techniqueScore, paceScore);
    final overallSummary = _overallSummary(
      ctx,
      overallScore,
      quickPro,
      quickCon,
    );
    final techniqueSummary = _techniqueSummary(
      ctx,
      techniqueScore,
      suggestions,
      poseMetrics,
      quickPro,
      quickCon,
    );
    final paceSummary = _paceSummary(ctx, paceScore, quickPro, quickCon);

    return YouthFriendlyAnalysis.sanitizeAnalysis(
      SwimVideoAnalysis(
        swimVideoId: video.id,
        swimmer: video.swimmer,
        summary: '${ctx.eventLabel}\n$quickPro\n$quickCon',
        strengths: _formatSections(sections),
        improvements: 'Top 3 priorities for your next race\n'
            '${_bulletBlock(priorities)}',
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
          'top_3_priorities': priorities,
          'estimated_time_savings': timeSavings,
          'coach_notes_for_next_race': coachNotes,
          'quick_pro': quickPro,
          'quick_con': quickCon,
          'next_race_goal': nextRaceGoal,
          'dryland_focus': dryland,
          'overall_summary': overallSummary,
          'technique_summary': techniqueSummary,
          'pace_summary': paceSummary,
          'personal_best_seconds': ctx.personalBestSeconds,
          if (poseMetrics != null) 'pose_metrics': poseMetrics.toJson(),
          'engine': poseMetrics?.hasUsableMetrics == true
              ? 'swimiq-v1-notes-mediapipe'
              : 'swimiq-v1-notes',
        },
      ),
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
      items.add('Start phase may need sharpening for $event — log a reaction time to track it.');
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

  List<String> _positiveHighlights(
    _AnalysisContext ctx,
    SwimPoseMetrics? pose,
  ) {
    final items = <String>[];
    final s = ctx.noteSignals;
    final event = ctx.eventLabel;

    if (pose?.bodyMechanicsPro != null &&
        pose!.bodyMechanicsPro!.trim().isNotEmpty) {
      items.add(pose.bodyMechanicsPro!.trim());
    }

    if (s.finishExtensionMentioned == true) {
      items.add(YouthCoachingPhrases.finishStrongProForEvent(event));
    }

    if (s.reactionSeconds != null && s.reactionSeconds! <= 0.68) {
      items.add(
        'Quick reaction off the blocks (~${s.reactionSeconds!.toStringAsFixed(2)}s) — early speed is a strength for $event.',
      );
    }

    if (s.breakoutMeters != null && s.breakoutMeters! >= 10) {
      items.add(
        '${YouthCoachingPhrases.solidBreakoutPro} (around ${s.breakoutMeters}m).',
      );
    } else if (s.breakoutMeters != null && s.dolphinKickCount != null) {
      items.add(
        'Committed underwater work (${s.dolphinKickCount} dolphin kicks, '
        'coming up for your first stroke at ${s.breakoutMeters}m).',
      );
    }

    if (s.strokeCountPerLength != null) {
      final range = ctx.expectedStrokeCountRange;
      final spl = s.strokeCountPerLength!;
      if (range != null && spl >= range.$1 && spl <= range.$2) {
        items.add(
          'Stroke count (~$spl per length) stayed in a strong range for $event.',
        );
      }
    }

    if (s.tempoRushedLate != true && s.mentionsTempo) {
      items.add('Tempo held steady — rhythm stayed together through the race.');
    }

    if (pose != null && pose.hasUsableMetrics) {
      if (pose.hipDropDegrees != null && pose.hipDropDegrees! < 5) {
        items.add('Body line stayed flat — hips stayed near the surface on video.');
      }
      if (pose.kickSymmetryScore != null && pose.kickSymmetryScore! >= 78) {
        items.add('Even kick rhythm from both legs — steady power through the legs.');
      }
      if (pose.headLiftScore != null && pose.headLiftScore! < 0.25) {
        items.add('Head stayed low on breaths — cleaner body line through the stroke.');
      }
    }

    if (ctx.personalBestSeconds != null) {
      items.add(
        'You have official speed on the clock for $event — build on what already works.',
      );
    }

    if (items.isEmpty && s.mentionsBreakout) {
      items.add(YouthCoachingPhrases.breakoutAwarenessPro);
    }
    if (items.isEmpty && s.mentionsStart) {
      items.add(YouthCoachingPhrases.reviewedStartUnderwaterArrow);
    }
    if (items.isEmpty && ctx.notes.isNotEmpty) {
      items.add(
        'You logged race details for $event — that focus helps coaches see what you did well.',
      );
    }
    if (items.isEmpty) {
      items.add(
        'Video uploaded — add start, stroke count, and finish notes to highlight your next strength.',
      );
    }

    return items;
  }

  String _quickPro(_AnalysisContext ctx, SwimPoseMetrics? pose) {
    return '• ${_positiveHighlights(ctx, pose).first}';
  }

  String _quickCon(
    _AnalysisContext ctx,
    List<String> suggestions,
    SwimPoseMetrics? pose,
  ) {
    final s = ctx.noteSignals;

    if (pose?.bodyMechanicsCon != null &&
        pose!.bodyMechanicsCon!.trim().isNotEmpty) {
      return '• ${pose.bodyMechanicsCon!.trim()}';
    }
    if (s.reactionSeconds != null && s.reactionSeconds! > 0.70) {
      return '• Reaction time (~${s.reactionSeconds!.toStringAsFixed(2)}s) looks slow — early speed is leaking off the blocks.';
    }
    if (s.tempoRushedLate == true) {
      return '• Late-race tempo fades — length and rhythm drop when it matters most.';
    }
    if (s.breathesEveryStroke == true && ctx.isSprint) {
      return '• Breathing pattern may be costing rhythm on a sprint ${ctx.eventLabel}.';
    }
    if (s.mentionsStart && s.reactionSeconds == null) {
      return '• Start phase needs sharpening — tighten block setup and the first underwater push.';
    }
    if (suggestions.isNotEmpty) {
      final limiter = suggestions.firstWhere(
        (line) =>
            line.contains('costing') ||
            line.contains('high side') ||
            line.contains('low side') ||
            line.contains('disrupt') ||
            line.contains('fade') ||
            line.contains('sharpen') ||
            line.contains('flagged') ||
            line.contains('may need'),
        orElse: () => suggestions.length > 1 ? suggestions[1] : suggestions.first,
      );
      return '• $limiter';
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
      add(YouthCoachingPhrases.holdStreamlinePriority);
    }
    if (s.strokeCountPerLength != null) {
      final range = ctx.expectedStrokeCountRange;
      final spl = s.strokeCountPerLength!;
      if (range != null && spl > range.$2) {
        add('Lower stroke count without losing tempo.');
      } else if (range != null && spl < range.$1) {
        add(YouthCoachingPhrases.avoidOverGlidingBetweenStrokes);
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
      add(YouthCoachingPhrases.finishFocusPriority);
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
      add(
        'Race with a clear underwater kick count and a plan for your first stroke '
        'after you come up from underwater.',
      );
    }

    return items.take(3).toList();
  }

  String _estimatedTimeSavings(
    _AnalysisContext ctx,
    SwimPoseMetrics? pose,
  ) {
    final s = ctx.noteSignals;
    final lines = <_TimeSavingLine>[];

    void add(String limiter, double low, double high) {
      lines.add(_TimeSavingLine(limiter: limiter, low: low, high: high));
    }

    if (s.reactionSeconds != null && s.reactionSeconds! > 0.70) {
      add(
        'Sharper block reaction (notes: ${s.reactionSeconds!.toStringAsFixed(2)}s)',
        0.05,
        0.15,
      );
    }
    if (s.breakoutMeters != null && s.breakoutMeters! < 10) {
      add(
        '${YouthCoachingPhrases.longerUnderwaterBeforeFirstStroke} '
        '(${s.breakoutMeters}m noted)',
        0.10,
        0.20,
      );
    }
    if (s.strokeCountPerLength != null) {
      final range = ctx.expectedStrokeCountRange;
      final spl = s.strokeCountPerLength!;
      if (range != null && spl > range.$2) {
        add('One fewer stroke per length (~$spl now)', 0.10, 0.30);
      } else if (range != null && spl < range.$1) {
        add('Add rhythm without over-gliding (~$spl now)', 0.05, 0.15);
      }
    }
    if (s.tempoRushedLate == true) {
      add('Hold stroke length in the last ${ctx.isSprint ? '15m' : 'length'}', 0.10, 0.20);
    }
    if (s.breathesEveryStroke == true && ctx.isSprint) {
      add('One fewer breath on a ${ctx.distance}m ${ctx.stroke}', 0.05, 0.15);
    }
    if (s.mentionsFinish || s.finishExtensionMentioned == true) {
      add(YouthCoachingPhrases.completeLastStrokeReach, 0.05, 0.12);
    }

    if (pose != null && pose.hasUsableMetrics) {
      if (pose.hipDropDegrees != null && pose.hipDropDegrees! >= 6) {
        add(
          'Keep hips nearer the surface (MediaPipe hip drop ${pose.hipDropDegrees!.toStringAsFixed(0)}°)',
          0.08,
          0.22,
        );
      }
      if (pose.headLiftScore != null && pose.headLiftScore! >= 0.30) {
        add(
          'Lower head on breaths — head lift score ${pose.headLiftScore!.toStringAsFixed(2)}',
          0.05,
          0.14,
        );
      }
      if (pose.kickSymmetryScore != null && pose.kickSymmetryScore! < 72) {
        add(
          'Even kick rhythm both legs (symmetry ${pose.kickSymmetryScore!.toStringAsFixed(0)}/100)',
          0.04,
          0.12,
        );
      }
      if (pose.avgBodyLineAngleDeg != null && pose.avgBodyLineAngleDeg! > 14) {
        add(
          'Flatter body line through the stroke (${pose.avgBodyLineAngleDeg!.toStringAsFixed(0)}° avg)',
          0.06,
          0.18,
        );
      }
      if (lines.isEmpty && pose.bodyMechanicsCon != null) {
        add('Fix ${pose.bodyMechanicsCon!.toLowerCase()}', 0.08, 0.20);
      }
    }

    if (lines.isEmpty) {
      if (ctx.isSprint && ctx.stroke == 'Butterfly') {
        add('Cleaner breathing rhythm on the second 25', 0.08, 0.15);
        add(YouthCoachingPhrases.strongerFinishReach, 0.05, 0.10);
      } else if (ctx.isSprint) {
        add(YouthCoachingPhrases.tighterUnderwaterArrowOffWalls, 0.06, 0.14);
        add('Hold tempo through the last 15 meters', 0.05, 0.12);
      } else {
        add('Steadier pacing on the middle ${ctx.distance ~/ 2}m', 0.15, 0.35);
        add('Cleaner turns without losing momentum', 0.10, 0.25);
      }
    }

    final bullets = lines
        .map(
          (line) =>
              '• ${line.limiter}: ${line.low.toStringAsFixed(2)}–${line.high.toStringAsFixed(2)}s',
        )
        .join('\n');
    final totalLow = lines.fold<double>(0, (sum, line) => sum + line.low);
    final totalHigh = lines.fold<double>(0, (sum, line) => sum + line.high);

    return '$bullets\n\n'
        'Combined if you nail these on ${ctx.eventLabel}: '
        '${totalLow.toStringAsFixed(2)}–${totalHigh.toStringAsFixed(2)}s';
  }

  String _coachNotesForNextRace(
    _AnalysisContext ctx,
    List<String> priorities,
    SwimPoseMetrics? pose,
  ) {
    final name =
        ctx.profile?.preferredName ?? ctx.profile?.swimmerName ?? 'You';
    final lines = <String>[
      '$name — your race plan for ${ctx.eventLabel}:',
      'Behind the blocks: two calm breaths, loose shoulders, eyes on the starter.',
    ];

    if (ctx.noteSignals.reactionSeconds != null &&
        ctx.noteSignals.reactionSeconds! > 0.70) {
      lines.add(YouthCoachingPhrases.fastStartUnderwaterArrow);
    } else {
      lines.add(YouthCoachingPhrases.practicedStartCue);
    }

    switch (ctx.stroke) {
      case 'Butterfly':
        if (ctx.isSprint) {
          lines.add(
            'First 25: long strokes with hips up — breathe forward, not straight up.',
          );
          lines.add(
            'Second 25: keep your rhythm snapping; try one fewer breath if you feel strong.',
          );
        } else {
          lines.add(
            'Every length: stay long in front — breathe before you feel desperate.',
          );
        }
      case 'Backstroke':
        lines.add(
          'Stay patient on your start — hips high, steady kick, do not rush the catch.',
        );
      case 'Breaststroke':
        lines.add(
          'Long glide, quick pull — snap your kick and keep your head still on the surface.',
        );
      case 'Freestyle':
        lines.add(
          'Breathe to the side with one goggle in the water — hips rotate, do not lift your head.',
        );
      case 'IM':
        lines.add(
          'Race each stroke with a clear plan — transitions are free speed if you stay smooth.',
        );
      default:
        break;
    }

    if (pose?.bodyMechanicsCon != null && pose!.bodyMechanicsCon!.isNotEmpty) {
      lines.add('Video cue: ${pose.bodyMechanicsCon} — fix that every length.');
    } else if (priorities.isNotEmpty) {
      lines.add('Your #1 focus today: ${priorities.first}');
    }

    if (ctx.noteSignals.strokeCountPerLength != null) {
      lines.add(
        'Stroke-count check: aim for ~${ctx.noteSignals.strokeCountPerLength} per length without slowing down.',
      );
    }

    lines.add(YouthCoachingPhrases.finishWallReminder);

    if (ctx.personalBestSeconds != null) {
      lines.add(
        'You have gone ${SwimTime.fromSeconds(ctx.personalBestSeconds!)} — race smart and see if you can beat it.',
      );
    } else {
      lines.add('After the race: name one thing you nailed and one thing to try again.');
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

  int _techniqueScore(
    _AnalysisContext ctx,
    List<String> suggestions,
    SwimPoseMetrics? pose,
  ) {
    var score = 62;
    if (ctx.noteSignals.finishExtensionMentioned == true) score += 6;
    if (ctx.noteSignals.breakoutMeters != null &&
        ctx.noteSignals.breakoutMeters! >= 10) {
      score += 5;
    }
    if (suggestions.length >= 3) score += 4;
    if (pose?.hasUsableMetrics == true) {
      final metrics = pose!;
      if (metrics.hipDropDegrees != null && metrics.hipDropDegrees! < 5) {
        score += 7;
      }
      if (metrics.headLiftScore != null && metrics.headLiftScore! < 0.25) {
        score += 6;
      }
      if (metrics.kickSymmetryScore != null && metrics.kickSymmetryScore! >= 78) {
        score += 5;
      }
      if (metrics.hipDropDegrees != null && metrics.hipDropDegrees! >= 8) {
        score -= 8;
      }
      if (metrics.headLiftScore != null && metrics.headLiftScore! >= 0.35) {
        score -= 6;
      }
    }
    if (ctx.noteSignals.reactionSeconds != null &&
        ctx.noteSignals.reactionSeconds! > 0.70) {
      score -= 5;
    }
    if (ctx.noteSignals.tempoRushedLate == true) score -= 4;
    return score.clamp(52, 88);
  }

  int _paceScore(_AnalysisContext ctx) {
    var score = 64;
    if (ctx.noteSignals.reactionSeconds != null &&
        ctx.noteSignals.reactionSeconds! <= 0.68) {
      score += 8;
    }
    if (ctx.noteSignals.strokeCountPerLength != null) score += 4;
    if (ctx.noteSignals.tempoRushedLate != true) score += 6;
    if (ctx.noteSignals.tempoRushedLate == true) score -= 10;
    if (ctx.noteSignals.breathesEveryStroke == true && ctx.isSprint) {
      score -= 7;
    }
    if (ctx.personalBestSeconds != null) score += 4;
    return score.clamp(52, 88);
  }

  int _overallScore(
    _AnalysisContext ctx,
    int techniqueScore,
    int paceScore,
  ) {
    final blended = (techniqueScore * 0.55 + paceScore * 0.45).round();
    if (ctx.noteSignals.hasContent) {
      return (blended + 2).clamp(55, 90);
    }
    return blended.clamp(55, 88);
  }

  String _overallSummary(
    _AnalysisContext ctx,
    int score,
    String quickPro,
    String quickCon,
  ) {
    final good = _summarySnippet(quickPro);
    final work = _summarySnippet(quickCon);
    return _scoreSummaryLine(
      category: 'Race readiness',
      score: score,
      goingWell: good.isNotEmpty
          ? good
          : (ctx.noteSignals.hasContent
              ? 'you logged race details and stayed engaged through the swim.'
              : 'getting this race on video so you can learn from it.'),
      workOn: work.isNotEmpty
          ? work
          : 'start setup, underwater, and a complete finish at the wall.',
    );
  }

  String _techniqueSummary(
    _AnalysisContext ctx,
    int score,
    List<String> suggestions,
    SwimPoseMetrics? pose,
    String quickPro,
    String quickCon,
  ) {
    final s = ctx.noteSignals;
    String? goingWell;
    String? workOn;

    if (pose?.bodyMechanicsPro != null &&
        pose!.bodyMechanicsPro!.trim().isNotEmpty) {
      goingWell = pose.bodyMechanicsPro!.trim();
    } else if (s.finishExtensionMentioned == true) {
      goingWell =
          'you finished with a complete last stroke and a strong touch.';
    } else if (pose?.hipDropDegrees != null && pose!.hipDropDegrees! < 5) {
      goingWell = 'your body line stayed flat with hips near the surface.';
    } else {
      goingWell = _summarySnippet(quickPro);
    }

    if (pose?.bodyMechanicsCon != null &&
        pose!.bodyMechanicsCon!.trim().isNotEmpty) {
      workOn = pose.bodyMechanicsCon!.trim();
    } else if (s.breathesEveryStroke == true && ctx.isSprint) {
      workOn =
          'breathing every stroke on a sprint — try holding your breath a little longer.';
    } else if (suggestions.isNotEmpty) {
      workOn = _summarySnippet(suggestions.first);
    } else {
      workOn = _summarySnippet(quickCon);
    }

    return _scoreSummaryLine(
      category: 'Stroke mechanics',
      score: score,
      goingWell: goingWell ?? 'parts of your pull, kick, and body line are building.',
      workOn: workOn ?? 'hips up, head down, and a steady kick while you pull.',
    );
  }

  String _paceSummary(
    _AnalysisContext ctx,
    int score,
    String quickPro,
    String quickCon,
  ) {
    final s = ctx.noteSignals;
    String? goingWell;
    String? workOn;

    if (s.reactionSeconds != null && s.reactionSeconds! <= 0.68) {
      goingWell =
          'quick reaction off the blocks (~${s.reactionSeconds!.toStringAsFixed(2)}s).';
    } else if (s.tempoRushedLate != true && s.mentionsTempo) {
      goingWell = 'tempo stayed steady through the middle of the race.';
    } else {
      goingWell = _summarySnippet(quickPro);
    }

    if (s.tempoRushedLate == true) {
      workOn = 'tempo rushed late in the race — keep the same rhythm on the last length.';
    } else if (s.reactionSeconds != null && s.reactionSeconds! > 0.70) {
      workOn =
          'start reaction (~${s.reactionSeconds!.toStringAsFixed(2)}s) — tighten block setup.';
    } else {
      workOn = _summarySnippet(quickCon);
    }

    return _scoreSummaryLine(
      category: 'Tempo and rhythm',
      score: score,
      goingWell: goingWell ?? 'you are learning how your race speed feels.',
      workOn: workOn ?? 'even tempo from start through finish.',
    );
  }

  String _summarySnippet(String text) {
    final cleaned = text
        .replaceFirst(RegExp(r'^[•\-\*]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return '';
    final period = cleaned.indexOf('. ');
    if (period > 0 && period < 140) {
      return cleaned.substring(0, period + 1);
    }
    if (cleaned.length > 140) {
      return '${cleaned.substring(0, 137).trim()}…';
    }
    return cleaned;
  }

  String _scoreSummaryLine({
    required String category,
    required int score,
    required String goingWell,
    required String workOn,
  }) {
    final good = goingWell.trim().isEmpty
        ? 'keep building on what already feels strong.'
        : goingWell.trim();
    final work = workOn.trim().isEmpty
        ? 'one clear focus for your next race.'
        : workOn.trim();
    return '$category — Going well: $good Work on: $work';
  }
}

class _TimeSavingLine {
  const _TimeSavingLine({
    required this.limiter,
    required this.low,
    required this.high,
  });

  final String limiter;
  final double low;
  final double high;
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
