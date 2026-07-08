import '../../data/models/swim_goal.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';

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
    required this.injuryPrevention,
    required this.engineLabel,
  });

  final String headline;
  final String primaryStroke;
  final List<DrylandWorkoutBlock> workoutBlocks;
  final String recoveryNotes;
  final String injuryPrevention;
  final String engineLabel;
}

/// SwimIQ AI Dryland Coach — personalized strength, mobility, and recovery for Pro.
class AiDrylandCoachService {
  AiDrylandCoachService._();

  static const engineLabel =
      'SwimIQ AI Dryland Coach · personalized from your strokes, goals, and training load';

  static AiDrylandCoachPlan build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final profile = data.profile;
    final stroke = _primaryStroke(profile);
    final goal = data.goals.isNotEmpty ? data.goals.first : null;
    final sessionsThisWeek = _sessionsThisWeek(data.raceLogs.length);

    return AiDrylandCoachPlan(
      headline: 'Dryland plan for ${data.displayName(swimmer)}',
      primaryStroke: stroke,
      workoutBlocks: [
        _strengthBlock(stroke, goal),
        _coreBlock(stroke),
        _mobilityBlock(stroke),
      ],
      recoveryNotes: _recoveryNotes(sessionsThisWeek),
      injuryPrevention: _injuryPrevention(stroke),
      engineLabel: engineLabel,
    );
  }

  static String _primaryStroke(SwimmerProfile? profile) {
    final primary = profile?.primaryStroke?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final secondary = profile?.secondaryStroke?.trim();
    if (secondary != null && secondary.isNotEmpty) return secondary;
    return 'Freestyle';
  }

  static int _sessionsThisWeek(int totalSessions) =>
      totalSessions.clamp(0, 7);

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
      notes: 'Keep loads moderate — dryland supports pool training, it does not replace it.',
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
      return 'High training load detected. Prioritize sleep, hydration, and one full rest day. '
          'Light foam rolling and 10-minute mobility on off days.';
    }
    if (sessionsThisWeek >= 3) {
      return 'Solid week of training. Add a 10–15 minute mobility session after hard practices '
          'and fuel within 30 minutes post-workout.';
    }
    return 'Build consistency in the pool first. On dryland days, keep sessions short (15–20 min) '
        'and focus on movement quality.';
  }

  static String _injuryPrevention(String stroke) {
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
