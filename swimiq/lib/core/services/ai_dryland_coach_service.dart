import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';
import '../utils/swim_stroke_utils.dart';

class DrylandWorkoutBlock {
  const DrylandWorkoutBlock({
    required this.title,
    required this.focus,
    required this.exercises,
    required this.notes,
  });

  final String title;
  final String focus;
  final List<String> exercises;
  final String notes;
}

class AiDrylandCoachPlan {
  const AiDrylandCoachPlan({
    required this.headline,
    required this.primaryStroke,
    required this.workoutBlocks,
    required this.recoveryNotes,
    required this.injuryPreventionAndStability,
    required this.engineLabel,
    required this.sessionsThisWeek,
    required this.focusEvent,
  });

  final String headline;
  final String primaryStroke;
  final List<DrylandWorkoutBlock> workoutBlocks;
  final String recoveryNotes;
  final String injuryPreventionAndStability;
  final String engineLabel;
  final int sessionsThisWeek;
  final String focusEvent;
}

/// SwimIQ AI Dryland Coach — personalized strength, mobility, and recovery for Pro.
class AiDrylandCoachService {
  AiDrylandCoachService._();

  static const engineLabel =
      'SwimIQ AI Dryland Coach · personalized from your strokes, goals, training load, and video priorities';

  static AiDrylandCoachPlan build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final profile = data.profile;
    final goal = data.goals.isNotEmpty ? data.goals.first : null;
    final latestAnalysis = _latestAnalysis(data.userFacingVideoAnalyses);
    final stroke = _primaryStroke(
      profile: profile,
      goal: goal,
      personalBestStroke: data.personalBests.isNotEmpty
          ? data.personalBests.first.stroke
          : null,
      analysis: latestAnalysis,
    );
    final focusEvent = _focusEvent(profile: profile, goal: goal);
    final sessionsThisWeek = _sessionsThisWeek(data.raceLogs);
    final priorities = latestAnalysis?.topPriorities ?? const <String>[];

    final blocks = <DrylandWorkoutBlock>[
      _strengthBlock(stroke, goal),
      _coreBlock(stroke),
      _mobilityBlock(stroke),
    ];
    if (priorities.isNotEmpty) {
      blocks.insert(1, _techniqueInformedBlock(stroke, priorities));
    }

    return AiDrylandCoachPlan(
      headline:
          'Dryland plan for ${data.displayName(swimmer)} · $sessionsThisWeek pool sessions this week',
      primaryStroke: stroke,
      focusEvent: focusEvent,
      sessionsThisWeek: sessionsThisWeek,
      workoutBlocks: blocks,
      recoveryNotes: _recoveryNotes(sessionsThisWeek),
      injuryPreventionAndStability: _injuryPreventionAndStability(stroke),
      engineLabel: engineLabel,
    );
  }

  static String _primaryStroke({
    required SwimmerProfile? profile,
    required SwimGoal? goal,
    required String? personalBestStroke,
    required SwimVideoAnalysis? analysis,
  }) {
    final primary = profile?.primaryStroke?.trim();
    if (primary != null && primary.isNotEmpty) {
      return SwimStrokeUtils.canonical(primary);
    }
    final favorite = profile?.favoriteEvent?.trim();
    if (favorite != null && favorite.isNotEmpty) {
      return _strokeFromEventLabel(favorite);
    }
    if (goal != null && goal.event.trim().isNotEmpty) {
      return _strokeFromEventLabel(goal.event);
    }
    if (personalBestStroke != null && personalBestStroke.trim().isNotEmpty) {
      return SwimStrokeUtils.canonical(personalBestStroke);
    }
    final analysisStroke = analysis?.analysisJson?['stroke']?.toString();
    if (analysisStroke != null && analysisStroke.trim().isNotEmpty) {
      return SwimStrokeUtils.canonical(analysisStroke);
    }
    return 'Freestyle';
  }

  static String _focusEvent({
    required SwimmerProfile? profile,
    required SwimGoal? goal,
  }) {
    final favorite = profile?.favoriteEvent?.trim();
    if (favorite != null && favorite.isNotEmpty) return favorite;
    if (goal != null && goal.event.trim().isNotEmpty) return goal.event.trim();
    final primary = profile?.primaryStroke?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    return 'General swim fitness';
  }

  static String _strokeFromEventLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('fly') || lower.contains('butterfly')) return 'Butterfly';
    if (lower.contains('back')) return 'Backstroke';
    if (lower.contains('breast')) return 'Breaststroke';
    if (lower.contains('im') || lower.contains('medley')) return 'IM';
    return 'Freestyle';
  }

  static int _sessionsThisWeek(List<RaceLog> raceLogs, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return raceLogs.where((log) {
      final date = log.date;
      return !date.isBefore(start) && date.isBefore(end);
    }).length;
  }

  static SwimVideoAnalysis? _latestAnalysis(List<SwimVideoAnalysis> analyses) {
    if (analyses.isEmpty) return null;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }

  static DrylandWorkoutBlock _techniqueInformedBlock(
    String stroke,
    List<String> priorities,
  ) {
    final cues = priorities
        .take(3)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return DrylandWorkoutBlock(
      title: 'Technique-informed dryland',
      focus: 'Land work that supports your latest AI Coach priorities for $stroke',
      exercises: [
        for (final cue in cues) 'Cue transfer: $cue · 2× slow quality reps',
        'Band activation matching that limiter · 2×15',
        'Mirror drill / wall rehearsal for the same pattern · 2×8',
      ],
      notes:
          'Keep this block short. Quality over load — transfer the same feel into the pool.',
    );
  }

  static DrylandWorkoutBlock _strengthBlock(String stroke, SwimGoal? goal) {
    final eventHint = goal != null ? ' toward ${goal.event}' : '';
    return DrylandWorkoutBlock(
      title: 'Strength recommendations',
      focus: 'Build power that transfers to $stroke$eventHint',
      exercises: switch (stroke) {
        'Butterfly' => const [
            'Band pull-aparts · 3×15',
            'Push-up to downward dog · 3×8',
            'Lat pulldown or band lat pull · 3×12',
            'Medicine-ball chest pass · 3×10',
          ],
        'Breaststroke' => const [
            'Goblet squat · 3×10',
            'Single-leg RDL · 3×8 each leg',
            'Chest-supported row · 3×12',
            'Hip thrust · 3×12',
          ],
        'Backstroke' => const [
            'Pull-ups or band-assisted pull-ups · 3×6–10',
            'Romanian deadlift · 3×10',
            'Face pulls · 3×15',
            'Split squat · 3×8 each leg',
          ],
        'IM' => const [
            'Front squat · 3×8',
            'Pull-ups · 3×6–10',
            'Push press · 3×8',
            'Single-leg RDL · 3×8 each leg',
          ],
        _ => const [
            'Pull-ups or band rows · 3×10',
            'Split squat · 3×8 each leg',
            'Push-ups · 3×12',
            'Plank shoulder taps · 3×20',
          ],
      },
      notes:
          'Keep loads moderate — dryland supports pool training, it does not replace it.',
    );
  }

  static DrylandWorkoutBlock _coreBlock(String stroke) {
    return DrylandWorkoutBlock(
      title: 'Core & stability',
      focus: 'Hold body line and rotation under fatigue ($stroke)',
      exercises: const [
        'Dead bug · 3×10 each side',
        'Side plank with reach · 3×30 sec each side',
        'Pallof press · 3×12 each side',
        'Bird dog · 3×8 each side',
      ],
      notes: 'Exhale on effort; keep ribs stacked over hips.',
    );
  }

  static DrylandWorkoutBlock _mobilityBlock(String stroke) {
    return DrylandWorkoutBlock(
      title: 'Mobility & flexibility',
      focus: 'Open shoulders and hips for efficient $stroke mechanics',
      exercises: switch (stroke) {
        'Butterfly' => const [
            'Thoracic spine rotations · 2×8 each side',
            'Wall angels · 2×12',
            'Hip flexor stretch · 45 sec each side',
            'Ankle rocks · 2×15 each side',
          ],
        'Breaststroke' => const [
            'Hip 90/90 switches · 2×8 each side',
            'Frog stretch · 45 sec',
            'Shoulder CARs · 2×5 each direction',
            'Ankle dorsiflexion rocks · 2×15',
          ],
        _ => const [
            'Thread the needle · 2×8 each side',
            'Lat stretch on bench · 45 sec each side',
            'Ankle mobility rocks · 2×15',
            'Hip flexor stretch · 45 sec each side',
          ],
      },
      notes: 'Move slowly — mobility is not a race.',
    );
  }

  static String _recoveryNotes(int sessionsThisWeek) {
    if (sessionsThisWeek >= 5) {
      return 'High training load this week. Prioritize sleep, hydration, and one full rest day. '
          'Light foam rolling and 10-minute mobility on off days.';
    }
    if (sessionsThisWeek >= 3) {
      return 'Solid week of training. Add a 10–15 minute mobility session after hard practices '
          'and fuel within 30 minutes post-workout.';
    }
    return 'Build consistency in the pool first. On dryland days, keep sessions short (15–20 min) '
        'and focus on movement quality.';
  }

  static String _injuryPreventionAndStability(String stroke) {
    return switch (stroke) {
      'Butterfly' =>
        'Watch shoulder volume — pair pull-heavy days with band external rotation. '
            'Stop if sharp shoulder pain appears during fly work.',
      'Breaststroke' =>
        'Protect knees — keep squat depth pain-free and add hip abductor strength. '
            'Warm up kick patterns before max-effort breast sets.',
      'Backstroke' =>
        'Balance pull volume with scapular stability. Avoid over-arching on land core work.',
      _ =>
        'Rotate hard dryland days with easy pool days. Report persistent pain to your coach early.',
    };
  }
}
