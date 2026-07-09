import '../../data/models/swim_goal.dart';
import '../../data/models/swim_schedule_entry.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../data/models/swimmer_profile.dart';
import '../../core/utils/passport_metrics.dart';
import '../../providers/swimmer_data_provider.dart';

class RaceIntelligencePlan {
  const RaceIntelligencePlan({
    required this.headline,
    required this.focusEvent,
    required this.meetDayLabel,
    required this.middayChecklist,
    required this.warmUpPlan,
    required this.nutritionPlan,
    required this.hydrationNotes,
    required this.engineLabel,
  });

  final String headline;
  final String focusEvent;
  final String meetDayLabel;
  final List<RaceChecklistItem> middayChecklist;
  final List<String> warmUpPlan;
  final List<NutritionBlock> nutritionPlan;
  final String hydrationNotes;
  final String engineLabel;
}

class RaceChecklistItem {
  const RaceChecklistItem({
    required this.title,
    required this.detail,
    required this.timingHint,
  });

  final String title;
  final String detail;
  final String timingHint;
}

class NutritionBlock {
  const NutritionBlock({
    required this.mealLabel,
    required this.timing,
    required this.suggestions,
    required this.avoid,
  });

  final String mealLabel;
  final String timing;
  final List<String> suggestions;
  final String avoid;
}

/// SwimIQ Race Intelligence™ — meet-day checklist, warm-up, and AI nutrition plan.
class RaceIntelligenceService {
  RaceIntelligenceService._();

  static const engineLabel =
      'SwimIQ AI Race Intelligence™ · personalized from your schedule, goals, and coaching data';

  static RaceIntelligencePlan build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final snapshot = data.passportSnapshot(swimmer);
    final upcoming = _upcomingSchedule(data.schedules);
    final latestAnalysis = _latestAnalysis(data.userFacingVideoAnalyses);
    final priorities = latestAnalysis?.topPriorities ?? const <String>[];
    final focusEvent = _focusEvent(
      upcoming: upcoming,
      snapshot: snapshot,
      goals: data.goals,
      profile: data.profile,
    );
    final meetLabel = upcoming != null
        ? '${upcoming.title} · ${_formatDate(upcoming.scheduleDate)}'
        : snapshot.nextMeet != 'No meets logged'
            ? snapshot.nextMeet
            : 'Add a meet or race in your schedule depot';

    return RaceIntelligencePlan(
      headline: 'Meet-day plan for ${data.displayName(swimmer)}',
      focusEvent: focusEvent,
      meetDayLabel: meetLabel,
      middayChecklist: _middayChecklist(
        upcoming: upcoming,
        focusEvent: focusEvent,
        priorities: priorities,
      ),
      warmUpPlan: _warmUpPlan(
        focusEvent: focusEvent,
        profile: data.profile,
        priorities: priorities,
        readiness: snapshot.readiness,
      ),
      nutritionPlan: _nutritionPlan(
        profile: data.profile,
        focusEvent: focusEvent,
        upcoming: upcoming,
      ),
      hydrationNotes: _hydrationNotes(focusEvent: focusEvent),
      engineLabel: engineLabel,
    );
  }

  static SwimScheduleEntry? _upcomingSchedule(List<SwimScheduleEntry> schedules) {
    if (schedules.isEmpty) return null;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final future = schedules.where((entry) {
      final day = DateTime(
        entry.scheduleDate.year,
        entry.scheduleDate.month,
        entry.scheduleDate.day,
      );
      return !day.isBefore(startOfToday);
    }).toList()
      ..sort((a, b) {
        final dateCompare = a.scheduleDate.compareTo(b.scheduleDate);
        if (dateCompare != 0) return dateCompare;
        return (a.startTime ?? '').compareTo(b.startTime ?? '');
      });
    return future.isNotEmpty ? future.first : schedules.last;
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

  static String _focusEvent({
    required SwimScheduleEntry? upcoming,
    required PassportSnapshot snapshot,
    required List<SwimGoal> goals,
    required SwimmerProfile? profile,
  }) {
    if (upcoming?.eventsLine?.trim().isNotEmpty == true) {
      return upcoming!.eventsLine!.trim().split('\n').first.trim();
    }
    if (goals.isNotEmpty) return goals.first.event;
    if (profile?.favoriteEvent?.trim().isNotEmpty == true) {
      return profile!.favoriteEvent!.trim();
    }
    return snapshot.currentFocus;
  }

  static List<RaceChecklistItem> _middayChecklist({
    required SwimScheduleEntry? upcoming,
    required String focusEvent,
    required List<String> priorities,
  }) {
    final raceTime = upcoming?.startTime?.trim();
    return [
      RaceChecklistItem(
        title: 'Gear & suit check',
        detail:
            'Goggles (spare pair), cap, suit, towel, water bottle, snack bag, heat sheet or SwimIQ schedule.',
        timingHint: raceTime != null ? 'Complete by 90 min before $raceTime' : 'Morning of meet',
      ),
      RaceChecklistItem(
        title: 'Midday fuel checkpoint',
        detail:
            'Eat your planned pre-race snack. Avoid heavy grease, new foods, or huge portions.',
        timingHint: '2.5–3 hours before $focusEvent',
      ),
      RaceChecklistItem(
        title: 'Hydration pulse',
        detail:
            'Sip water steadily — pale yellow urine is the target. Add electrolytes if the meet runs long or it is hot.',
        timingHint: 'Every 30–45 min until warm-up',
      ),
      RaceChecklistItem(
        title: 'Focus cue review',
        detail: priorities.isNotEmpty
            ? 'Race cue: ${priorities.first}'
            : 'Pick one technical cue for $focusEvent (start, breakout, tempo, or finish).',
        timingHint: '15 min before leaving for pool deck',
      ),
      RaceChecklistItem(
        title: 'Warm-up window',
        detail:
            'Confirm pool warm-up lane times, check blocks if allowed, and note your heat/lane.',
        timingHint: raceTime != null
            ? '45–60 min before $raceTime'
            : '45–60 min before first race',
      ),
      RaceChecklistItem(
        title: 'Post-race reset',
        detail:
            'Light stretch, hydration, and a small carb snack within 30 min for back-half events.',
        timingHint: 'After each race',
      ),
    ];
  }

  static List<String> _warmUpPlan({
    required String focusEvent,
    required SwimmerProfile? profile,
    required List<String> priorities,
    required String readiness,
  }) {
    final stroke = _strokeFromEvent(focusEvent, profile?.primaryStroke);
    final isDistance = _isDistanceEvent(focusEvent);
    final durationLabel = isDistance ? '10–15 min' : '8–12 min';

    final lines = <String>[
      'Event focus: $focusEvent · Primary stroke: $stroke · Readiness: $readiness',
      'Dryland warm-up · $durationLabel total (complete before pool warm-up lanes).',
      'Phase 1 — Activate (2 min): light jog or marching in place, 30 sec jumping jacks '
          '(low impact if legs are tired), 10 arm circles forward/back.',
      'Phase 2 — Mobility (3–4 min): 10 cross-body arm swings, 10 overhead reach-and-lean, '
          '${_mobilityCueForStroke(stroke)} '
          '10 leg swings each leg (front/back), 20 ankle circles each foot.',
    ];

    if (isDistance) {
      lines.add(
        'Phase 3 — Core & posture (2 min): 30 sec dead-bug or hollow hold, '
            '10 bird-dogs each side, 10 hip hinges with flat back — stay tall for distance pacing.',
      );
    } else {
      lines.add(
        'Phase 3 — Power primer (2–3 min): 8 bodyweight squats, 6 squat jumps (soft landing), '
            '4 explosive streamlines from squat — drive through legs like a start.',
      );
    }

    lines.add(
      'Phase 4 — Race activation (2–3 min): ${_raceActivationForStroke(stroke, focusEvent)}',
    );

    if (priorities.isNotEmpty) {
      lines.add('Technique cue carry-in: ${priorities.take(2).join(' · ')}');
    }

    lines.addAll([
      'Phase 5 — Start & mind (1–2 min): 2–3 dry block starts (or crouch explode if no blocks), '
          '10 sec race visualization for $focusEvent, cap & goggles on, confirm heat/lane.',
      'Finish: walk to pool warm-up calm and breathing steady — this dryland block primes the nervous system; '
          'save race pace for the water.',
    ]);

    return lines;
  }

  static String _strokeFromEvent(String event, String? primaryStroke) {
    final lower = event.toLowerCase();
    if (lower.contains('fly') || lower.contains('butterfly')) return 'Butterfly';
    if (lower.contains('back') || lower.contains('backstroke')) return 'Backstroke';
    if (lower.contains('breast')) return 'Breaststroke';
    if (lower.contains('free') || lower.contains('freestyle')) return 'Freestyle';
    if (lower.contains(' im') || lower.contains('individual medley')) return 'IM';
    return primaryStroke ?? 'Freestyle';
  }

  static String _mobilityCueForStroke(String stroke) {
    switch (stroke) {
      case 'Butterfly':
        return '8 thoracic extensions + chest openers for fly catch, ';
      case 'Backstroke':
        return '8 shoulder external-rotation pulses + hip flexor stretch each side, ';
      case 'Breaststroke':
        return '8 hip openers + 10 ankle dorsiflexion rocks for breast kick, ';
      case 'IM':
        return '6 reps each: thoracic rotation, hip opener, ankle rock, ';
      default:
        return '8 thoracic rotations each side for freestyle reach, ';
    }
  }

  static String _raceActivationForStroke(String stroke, String focusEvent) {
    switch (stroke) {
      case 'Butterfly':
        return '6 streamline pulses with strong core, 4 dolphin-kick arm drivers (standing), '
            '2×10 sec fly tempo arm swings — stay long through shoulders.';
      case 'Backstroke':
        return '6 streamline-to-backstroke arm cycles (standing), 8 fast double-arm back strokes '
            '(no resistance), 2×10 sec hip-up start drive.';
      case 'Breaststroke':
        return '6 standing breaststroke pull-throughs, 8 narrow squat-to-glide pulses, '
            '2×10 sec fast hands-to-chin tempo.';
      case 'IM':
        return '2 reps each stroke arm pattern (fly/back/breast/free), '
            '4 IM transition snaps (fly→back, back→breast), one smooth full-IM visualization.';
      default:
        return '6 freestyle catch pulls (standing), 8 high-elbow band pulls or arm drivers, '
            '2×10 sec race-pace arm tempo for $focusEvent.';
    }
  }

  static List<NutritionBlock> _nutritionPlan({
    required SwimmerProfile? profile,
    required String focusEvent,
    required SwimScheduleEntry? upcoming,
  }) {
    final age = profile?.age;
    final isDistance = _isDistanceEvent(focusEvent);
    final isSprint = !isDistance;

    final breakfastSuggestions = <String>[
      if (age != null && age <= 12)
        'Oatmeal with banana and a small glass of milk'
      else
        'Oatmeal or whole-grain toast with banana and nut butter',
      'Greek yogurt with berries (if dairy sits well)',
      'Water + optional small orange or apple',
    ];

    final snackSuggestions = isSprint
        ? [
            'Half a bagel or rice cakes with honey',
            'Fig bar or low-fiber granola bar',
            'Sports drink sip if racing in afternoon heat',
          ]
        : [
            'Banana + pretzels or dry cereal',
            'Peanut butter sandwich (light on the jelly)',
            'Electrolyte drink between prelims and finals',
          ];

    final preRaceSuggestions = isSprint
        ? [
            'Small carb bite only if 60+ min out: applesauce pouch or half banana',
            'Stop solid food 60–90 min before sprint races',
          ]
        : [
            'Light carb 2–3 hr out: toast, rice, or pasta (moderate portion)',
            'Small top-off 60 min out if hungry: banana or sports drink',
          ];

    final raceTime = upcoming?.startTime;
    final breakfastTiming = raceTime != null
        ? '3–4 hours before first race ($raceTime)'
        : '3–4 hours before first race';

    return [
      NutritionBlock(
        mealLabel: 'Breakfast / morning base',
        timing: breakfastTiming,
        suggestions: breakfastSuggestions,
        avoid: 'Skip sugary cereal alone, heavy bacon, or trying new foods.',
      ),
      NutritionBlock(
        mealLabel: 'Midday meet fuel',
        timing: '2–3 hours before $focusEvent',
        suggestions: snackSuggestions,
        avoid: 'No fried food, soda bursts, or large fatty meals between events.',
      ),
      NutritionBlock(
        mealLabel: 'Pre-race top-off',
        timing: '60–90 min before race',
        suggestions: preRaceSuggestions,
        avoid: 'No full meals, high fiber, or dairy if it bothers your stomach.',
      ),
      NutritionBlock(
        mealLabel: 'Recovery between events',
        timing: 'Within 30 min after each race',
        suggestions: [
          'Chocolate milk or protein + carb snack',
          'Water + electrolytes if sweating heavily',
          'Simple carbs if racing again within 2 hours',
        ],
        avoid: 'Skip energy drinks and heavy protein-only snacks mid-meet.',
      ),
    ];
  }

  static String _hydrationNotes({required String focusEvent}) {
    return 'SwimIQ AI Nutrition targets steady hydration for $focusEvent: '
        '8–12 oz water each hour on meet day, more in warm pools. '
        'This is general guidance — confirm with your coach or a sports dietitian.';
  }

  static bool _isDistanceEvent(String event) {
    final lower = event.toLowerCase();
    if (lower.contains('500') ||
        lower.contains('1000') ||
        lower.contains('1650') ||
        lower.contains('1500') ||
        lower.contains('400 im') ||
        lower.contains('200 ')) {
      return true;
    }
    return false;
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
