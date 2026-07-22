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
    required this.meetEvents,
    required this.meetDayLabel,
    required this.syncedToSchedule,
    required this.middayChecklist,
    required this.warmUpPhases,
    required this.warmUpPlan,
    required this.nutritionPlan,
    required this.hydrationNotes,
    required this.timeline,
    required this.engineLabel,
    this.meetTitle,
    this.meetLocation,
    this.meetDate,
    this.meetStartTime,
  });

  final String headline;
  final String focusEvent;
  final List<String> meetEvents;
  final String meetDayLabel;
  final bool syncedToSchedule;
  final String? meetTitle;
  final String? meetLocation;
  final DateTime? meetDate;
  final String? meetStartTime;
  final List<RaceTimelineStep> timeline;
  final List<RaceChecklistItem> middayChecklist;
  final List<WarmUpPhase> warmUpPhases;
  final List<String> warmUpPlan;
  final List<NutritionBlock> nutritionPlan;
  final String hydrationNotes;
  final String engineLabel;
}

class RaceTimelineStep {
  const RaceTimelineStep({
    required this.label,
    required this.detail,
    required this.iconName,
  });

  final String label;
  final String detail;
  final String iconName;
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

class WarmUpPhase {
  const WarmUpPhase({
    required this.phaseNumber,
    required this.title,
    required this.duration,
    required this.detail,
    required this.iconName,
  });

  final int phaseNumber;
  final String title;
  final String duration;
  final String detail;
  final String iconName;
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
      'SwimIQ AI Race Intelligence™ · synced to your upcoming meet, goals, and coaching data';

  static RaceIntelligencePlan build({
    required SwimmerData data,
    required String swimmer,
    String? selectedFocusEvent,
  }) {
    final snapshot = data.passportSnapshot(swimmer);
    final upcoming = _upcomingMeetOrRace(data.schedules);
    final latestAnalysis = _latestAnalysis(data.userFacingVideoAnalyses);
    final priorities = latestAnalysis?.topPriorities ?? const <String>[];
    final meetEvents = candidateEvents(
      data: data,
      swimmer: swimmer,
      upcoming: upcoming,
      snapshot: snapshot,
    );
    final focusEvent = _resolveFocusEvent(
      selectedFocusEvent: selectedFocusEvent,
      meetEvents: meetEvents,
      upcoming: upcoming,
      snapshot: snapshot,
      goals: data.goals,
      profile: data.profile,
    );
    final synced = upcoming != null;
    final meetLabel = upcoming != null
        ? '${upcoming.title} · ${_formatDate(upcoming.scheduleDate)}'
        : 'Next-meet plan (add a meet on Log → Schedule to sync)';

    final phases = _warmUpPhases(
      focusEvent: focusEvent,
      profile: data.profile,
      priorities: priorities,
      readiness: snapshot.readiness,
    );

    return RaceIntelligencePlan(
      headline: synced
          ? 'Meet-day plan for ${data.displayName(swimmer)}'
          : 'Race-day plan for ${data.displayName(swimmer)}',
      focusEvent: focusEvent,
      meetEvents: meetEvents,
      meetDayLabel: meetLabel,
      syncedToSchedule: synced,
      meetTitle: upcoming?.title,
      meetLocation: upcoming?.location,
      meetDate: upcoming?.scheduleDate,
      meetStartTime: upcoming?.startTime,
      timeline: _timeline(
        upcoming: upcoming,
        focusEvent: focusEvent,
        meetEvents: meetEvents,
      ),
      middayChecklist: _middayChecklist(
        upcoming: upcoming,
        focusEvent: focusEvent,
        meetEvents: meetEvents,
        priorities: priorities,
      ),
      warmUpPhases: phases,
      warmUpPlan: _warmUpPlanLines(phases, focusEvent, data.profile, snapshot.readiness),
      nutritionPlan: _nutritionPlan(
        profile: data.profile,
        focusEvent: focusEvent,
        meetEvents: meetEvents,
        upcoming: upcoming,
      ),
      hydrationNotes: _hydrationNotes(
        focusEvent: focusEvent,
        meetEvents: meetEvents,
      ),
      engineLabel: engineLabel,
    );
  }

  /// Events available for this plan — schedule first, then goals / PBs / favorites.
  static List<String> candidateEvents({
    required SwimmerData data,
    required String swimmer,
    SwimScheduleEntry? upcoming,
    PassportSnapshot? snapshot,
  }) {
    upcoming ??= _upcomingMeetOrRace(data.schedules);
    snapshot ??= data.passportSnapshot(swimmer);
    final events = <String>[];

    void add(String? raw) {
      final text = raw?.trim();
      if (text == null || text.isEmpty) return;
      if (events.any((e) => e.toLowerCase() == text.toLowerCase())) return;
      events.add(text);
    }

    for (final line in _parseEventsLine(upcoming?.eventsLine)) {
      add(line);
    }
    for (final goal in data.goals) {
      add(goal.event);
    }
    for (final pb in data.personalBests.take(6)) {
      add('${pb.displayTitle} ${pb.course}'.trim());
    }
    add(data.profile?.favoriteEvent);
    if (events.isEmpty) add(snapshot.currentFocus);
    if (events.isEmpty) add('100 Freestyle');
    return events.take(8).toList();
  }

  static List<String> _parseEventsLine(String? eventsLine) {
    final text = eventsLine?.trim();
    if (text == null || text.isEmpty) return const [];
    final parts = text
        .split(RegExp(r'[\n,;|/]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts;
  }

  static SwimScheduleEntry? _upcomingMeetOrRace(
    List<SwimScheduleEntry> schedules,
  ) {
    if (schedules.isEmpty) return null;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    bool isFuture(SwimScheduleEntry entry) {
      final day = DateTime(
        entry.scheduleDate.year,
        entry.scheduleDate.month,
        entry.scheduleDate.day,
      );
      return !day.isBefore(startOfToday);
    }

    int compareEntries(SwimScheduleEntry a, SwimScheduleEntry b) {
      final dateCompare = a.scheduleDate.compareTo(b.scheduleDate);
      if (dateCompare != 0) return dateCompare;
      return (a.startTime ?? '').compareTo(b.startTime ?? '');
    }

    final meetLike = schedules.where((e) => e.isMeet || e.isRace).toList();
    final futureMeets = meetLike.where(isFuture).toList()..sort(compareEntries);
    if (futureMeets.isNotEmpty) return futureMeets.first;
    if (meetLike.isNotEmpty) {
      meetLike.sort(compareEntries);
      return meetLike.last;
    }

    final futureAny = schedules.where(isFuture).toList()..sort(compareEntries);
    return futureAny.isNotEmpty ? futureAny.first : null;
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

  static String _resolveFocusEvent({
    required String? selectedFocusEvent,
    required List<String> meetEvents,
    required SwimScheduleEntry? upcoming,
    required PassportSnapshot snapshot,
    required List<SwimGoal> goals,
    required SwimmerProfile? profile,
  }) {
    final selected = selectedFocusEvent?.trim();
    if (selected != null &&
        selected.isNotEmpty &&
        meetEvents.any((e) => e.toLowerCase() == selected.toLowerCase())) {
      return meetEvents.firstWhere(
        (e) => e.toLowerCase() == selected.toLowerCase(),
      );
    }
    if (meetEvents.isNotEmpty) return meetEvents.first;
    if (upcoming?.eventsLine?.trim().isNotEmpty == true) {
      return _parseEventsLine(upcoming!.eventsLine).first;
    }
    if (goals.isNotEmpty) return goals.first.event;
    if (profile?.favoriteEvent?.trim().isNotEmpty == true) {
      return profile!.favoriteEvent!.trim();
    }
    return snapshot.currentFocus;
  }

  static List<RaceTimelineStep> _timeline({
    required SwimScheduleEntry? upcoming,
    required String focusEvent,
    required List<String> meetEvents,
  }) {
    final raceTime = upcoming?.startTime?.trim();
    final eventCount = meetEvents.length;
    return [
      RaceTimelineStep(
        label: 'Morning base',
        detail: raceTime != null
            ? 'Breakfast 3–4 hrs before $raceTime'
            : 'Breakfast 3–4 hrs before first race',
        iconName: 'breakfast',
      ),
      RaceTimelineStep(
        label: 'Arrive / check-in',
        detail: upcoming?.location?.trim().isNotEmpty == true
            ? 'At ${upcoming!.location!.trim()}'
            : 'Confirm heat sheet & lane assignments',
        iconName: 'arrive',
      ),
      RaceTimelineStep(
        label: 'Dryland + pool warm-up',
        detail: eventCount > 1
            ? 'Prime for $eventCount events · focus $focusEvent'
            : 'Prime nervous system for $focusEvent',
        iconName: 'warmup',
      ),
      RaceTimelineStep(
        label: 'Race window',
        detail: eventCount > 1
            ? 'Race plan covers: ${meetEvents.take(3).join(' · ')}'
            : 'Focus race: $focusEvent',
        iconName: 'race',
      ),
      RaceTimelineStep(
        label: 'Recover & reset',
        detail: 'Fuel + hydrate between events, cool down after finals',
        iconName: 'recover',
      ),
    ];
  }

  static List<RaceChecklistItem> _middayChecklist({
    required SwimScheduleEntry? upcoming,
    required String focusEvent,
    required List<String> meetEvents,
    required List<String> priorities,
  }) {
    final raceTime = upcoming?.startTime?.trim();
    final multi = meetEvents.length > 1;
    return [
      RaceChecklistItem(
        title: 'Gear & suit check',
        detail:
            'Goggles (spare pair), cap, suit, towel, water bottle, snack bag, heat sheet or SwimIQ schedule.',
        timingHint:
            raceTime != null ? 'Complete by 90 min before $raceTime' : 'Morning of meet',
      ),
      RaceChecklistItem(
        title: multi ? 'Event sheet review' : 'Focus event review',
        detail: multi
            ? 'Today’s events: ${meetEvents.join(' · ')}. Primary focus for cues & fueling: $focusEvent.'
            : 'Confirm heat/lane and one technical cue for $focusEvent.',
        timingHint: 'When you get the heat sheet',
      ),
      RaceChecklistItem(
        title: 'Midday fuel checkpoint',
        detail:
            'Eat familiar fuel only: oatmeal + banana, Kodiak waffles, honey, organic '
            'berry chews, sushi rice bites, or a protein bar. No new foods or heavy grease.',
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
        detail: multi
            ? 'Light stretch, hydration, and a small carb snack within 30 min — protect later events.'
            : 'Light stretch, hydration, and a small carb snack within 30 min.',
        timingHint: 'After each race',
      ),
    ];
  }

  static List<WarmUpPhase> _warmUpPhases({
    required String focusEvent,
    required SwimmerProfile? profile,
    required List<String> priorities,
    required String readiness,
  }) {
    final stroke = _strokeFromEvent(focusEvent, profile?.primaryStroke);
    final isDistance = _isDistanceEvent(focusEvent);
    final phases = <WarmUpPhase>[
      WarmUpPhase(
        phaseNumber: 1,
        title: 'Activate',
        duration: '2 min',
        detail:
            'Light jog or marching, 30 sec jumping jacks (low impact if tired), '
            '10 arm circles forward/back. Readiness: $readiness.',
        iconName: 'activate',
      ),
      WarmUpPhase(
        phaseNumber: 2,
        title: 'Mobility',
        duration: '3–4 min',
        detail:
            '10 cross-body arm swings, 10 overhead reach-and-lean, '
            '${_mobilityCueForStroke(stroke)}'
            '10 leg swings each leg, 20 ankle circles each foot.',
        iconName: 'mobility',
      ),
      WarmUpPhase(
        phaseNumber: 3,
        title: isDistance ? 'Core & posture' : 'Power primer',
        duration: isDistance ? '2 min' : '2–3 min',
        detail: isDistance
            ? '30 sec dead-bug or hollow hold, 10 bird-dogs each side, '
                '10 hip hinges with flat back — stay tall for distance pacing.'
            : '8 bodyweight squats, 6 squat jumps (soft landing), '
                '4 explosive streamlines from squat — drive through legs like a start.',
        iconName: 'power',
      ),
      WarmUpPhase(
        phaseNumber: 4,
        title: 'Race activation',
        duration: '2–3 min',
        detail: _raceActivationForStroke(stroke, focusEvent),
        iconName: 'activation',
      ),
      WarmUpPhase(
        phaseNumber: 5,
        title: 'Start & mind',
        duration: '1–2 min',
        detail: priorities.isNotEmpty
            ? '2–3 dry starts, visualize $focusEvent, cue: ${priorities.first}. Cap & goggles on.'
            : '2–3 dry starts (or crouch explode), 10 sec race visualization for $focusEvent, '
                'cap & goggles on, confirm heat/lane.',
        iconName: 'mind',
      ),
    ];
    return phases;
  }

  static List<String> _warmUpPlanLines(
    List<WarmUpPhase> phases,
    String focusEvent,
    SwimmerProfile? profile,
    String readiness,
  ) {
    final stroke = _strokeFromEvent(focusEvent, profile?.primaryStroke);
    final isDistance = _isDistanceEvent(focusEvent);
    final durationLabel = isDistance ? '10–15 min' : '8–12 min';
    return [
      'Event focus: $focusEvent · Primary stroke: $stroke · Readiness: $readiness',
      'Dryland warm-up · $durationLabel total (complete before pool warm-up lanes).',
      for (final phase in phases)
        'Phase ${phase.phaseNumber} — ${phase.title} (${phase.duration}): ${phase.detail}',
      'Finish: walk to pool warm-up calm and breathing steady — this dryland block primes the nervous system; '
          'save race pace for the water.',
    ];
  }

  static String _strokeFromEvent(String event, String? primaryStroke) {
    final lower = event.toLowerCase();
    if (lower.contains('fly') || lower.contains('butterfly')) return 'Butterfly';
    if (lower.contains('back') || lower.contains('backstroke')) return 'Backstroke';
    if (lower.contains('breast')) return 'Breaststroke';
    if (lower.contains('free') || lower.contains('freestyle')) return 'Freestyle';
    if (lower.contains(' im') ||
        lower.endsWith('im') ||
        lower.contains('individual medley')) {
      return 'IM';
    }
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
    required List<String> meetEvents,
    required SwimScheduleEntry? upcoming,
  }) {
    final age = profile?.age;
    final isDistance = _isDistanceEvent(focusEvent) ||
        meetEvents.any(_isDistanceEvent);
    final isSprint = !isDistance;
    final caffeineOk = age != null && age >= 14;
    final multi = meetEvents.length > 1;

    final breakfastSuggestions = <String>[
      'Oatmeal with banana and honey (meet-day classic — steady carbs, easy on the stomach)',
      'Kodiak protein waffles with banana or a drizzle of honey',
      'Scrambled or hard-boiled egg + whole-grain toast with peanut butter',
      if (age != null && age <= 12)
        'Small glass of milk or water with breakfast if dairy sits well'
      else
        'Greek yogurt with organic berries (if dairy sits well)',
      'Water; add electrolytes if the meet starts late morning',
    ];

    final snackSuggestions = <String>[
      'Banana (easy digesting potassium + carbs)',
      'Oatmeal cup or plain instant oats made with water',
      'Rice-based sushi bites / onigiri (plain, cucumber, or cooked filling — skip raw fish on meet day)',
      'Honey packet or honey on rice cakes / half bagel',
      if (caffeineOk)
        'Sushi bites or honey waffle with electrolytes + caffeine (e.g. Honey Stinger, Kodiak caffeinated waffle) — only if tested in practice'
      else
        'Honey + electrolyte bite or chew (caffeine-free) — test in practice first',
      'Organic berry energy chews or gummies (low fiber, familiar brand)',
      'Protein bar (half for sprints, light full bar for distance days)',
      if (isSprint)
        'Fig bar or pretzels between prelims and finals'
      else
        'Pretzels or dry cereal alongside fuel for long sessions',
      if (multi) 'Pack 2–3 snack options — multi-event days need flexible fueling',
      'Electrolyte drink sip (not chug) if racing in heat or long session',
    ];

    final preRaceSuggestions = isSprint
        ? [
            '60–90 min out: half banana, applesauce pouch, or 1–2 organic berry chews',
            '30–45 min out: small honey sip or electrolyte-only — stop solids 60 min before sprint races',
            if (caffeineOk)
              'Caffeine only if coach/parent approved and you have used it before hard sets (never first-time on meet day)',
          ]
        : [
            '2–3 hr out: oatmeal, rice, pasta, or sushi rice bites (moderate portion)',
            '60–90 min out: banana, honey, or organic berry chews if still hungry',
            'Electrolyte drink between prelims and finals for 200+ events',
          ];

    final recoverySuggestions = <String>[
      'Chocolate milk or protein + carb snack within 30 min',
      'Banana + honey or half protein bar if racing again within 2 hours',
      'Water + electrolytes if sweating heavily',
      'Organic berry chews for quick carbs before the next heat (small portion)',
      if (multi) 'Keep snacks staged by event so later races stay fueled',
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
        avoid:
            'Skip sugary cereal alone, heavy bacon, greasy breakfast sandwiches, energy drinks, or anything you have not eaten before practice.',
      ),
      NutritionBlock(
        mealLabel: 'Midday meet fuel',
        timing: multi
            ? '2–3 hours before primary focus ($focusEvent)'
            : '2–3 hours before $focusEvent',
        suggestions: snackSuggestions,
        avoid:
            'Skip fried food, soda, giant meals, high-fiber bars, raw/new sushi, and untested supplements on meet day.',
      ),
      NutritionBlock(
        mealLabel: 'Pre-race top-off',
        timing: '60–90 min before race',
        suggestions: preRaceSuggestions,
        avoid:
            'No full meals, greasy food, dairy if it upsets your stomach, or caffeine if you are under 14 or have not tested it.',
      ),
      NutritionBlock(
        mealLabel: 'Recovery between events',
        timing: 'Within 30 min after each race',
        suggestions: recoverySuggestions,
        avoid:
            'Skip energy drinks, heavy protein-only snacks, and large portions if you race again soon.',
      ),
    ];
  }

  static String _hydrationNotes({
    required String focusEvent,
    required List<String> meetEvents,
  }) {
    final multi = meetEvents.length > 1;
    return multi
        ? 'SwimIQ AI Nutrition for a multi-event day (focus $focusEvent): sip 8–12 oz water each hour; '
            'add electrolytes between races. Carbs first (banana, oatmeal, honey, berry gummies), '
            'light protein as needed — confirm with your coach or sports dietitian.'
        : 'SwimIQ AI Nutrition for $focusEvent: sip 8–12 oz water each hour on meet day; '
            'add electrolytes (especially with honey chews or caffeine fuel) in warm pools or long sessions. '
            'Carbs first (banana, oatmeal, honey, berry gummies), light protein as needed — confirm with your coach or sports dietitian.';
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
