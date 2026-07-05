import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/meet_result.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';

/// Meet-day race plans, pacing targets, and event-specific tips.
class RaceIntelligencePlan {
  const RaceIntelligencePlan({
    required this.event,
    required this.course,
    required this.headline,
    required this.strategy,
    required this.raceTips,
    this.goalTime,
    this.currentPb,
    this.standardsTarget,
    this.targetDate,
    this.meetName,
  });

  final String event;
  final String course;
  final String headline;
  final String strategy;
  final List<String> raceTips;
  final String? goalTime;
  final String? currentPb;
  final String? standardsTarget;
  final DateTime? targetDate;
  final String? meetName;
}

class RaceIntelligenceBrief {
  const RaceIntelligenceBrief({
    required this.headline,
    required this.summary,
    required this.meetDayTips,
    required this.warmupTips,
    required this.racePlans,
    this.nextMeetName,
    this.nextMeetDate,
  });

  final String headline;
  final String summary;
  final List<String> meetDayTips;
  final List<String> warmupTips;
  final List<RaceIntelligencePlan> racePlans;
  final String? nextMeetName;
  final DateTime? nextMeetDate;
}

abstract final class RaceIntelligenceService {
  static RaceIntelligenceBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final now = DateTime.now();
    final upcomingGoals = data.goals
        .where((goal) => !goal.targetDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    final recentMeet = _mostRecentMeet(data.meetResults);
    final pbs = data.personalBests;

    final plans = <RaceIntelligencePlan>[];
    if (upcomingGoals.isNotEmpty) {
      for (final goal in upcomingGoals.take(4)) {
        plans.add(_planForGoal(
          goal: goal,
          profile: data.profile,
          catalog: data.motivationalStandards,
          pbs: pbs,
          recentMeet: recentMeet,
        ));
      }
    } else if (data.meetResults.isNotEmpty) {
      for (final result in data.meetResults.take(3)) {
        plans.add(_planForMeetResult(
          result: result,
          profile: data.profile,
          catalog: data.motivationalStandards,
          pbs: pbs,
        ));
      }
    } else {
      final focus = data.passportSnapshot(swimmer).currentFocus;
      plans.add(
        RaceIntelligencePlan(
          event: focus,
          course: 'SCY',
          headline: 'Build your first meet race plan',
          strategy:
              'Add goals with target meet dates, then log meet results so '
              'Race Intelligence can tailor pace and race-day advice.',
          raceTips: const [
            'Write a goal time and course before the meet.',
            'Log post-race notes in Meets tab for split review.',
            'Use Video Lab the week before to lock technique fixes.',
          ],
        ),
      );
    }

    final nextGoal = upcomingGoals.isNotEmpty ? upcomingGoals.first : null;

    return RaceIntelligenceBrief(
      headline: nextGoal != null
          ? 'Race plan for ${nextGoal.event}'
          : 'Meet & race intelligence',
      summary:
          'Race Intelligence™ is meet-specific — pacing, strategy, and '
          'event tips. AI Coach handles technique fixes from video; Video Lab '
          'runs the full frame-by-frame critique.',
      meetDayTips: _meetDayTips(nextGoal, recentMeet),
      warmupTips: _warmupTips(data.profile?.primaryStroke),
      racePlans: plans,
      nextMeetName: recentMeet?.meetName,
      nextMeetDate: nextGoal?.targetDate ?? recentMeet?.meetDate,
    );
  }

  static MeetResult? _mostRecentMeet(List<MeetResult> results) {
    if (results.isEmpty) return null;
    final sorted = [...results]..sort((a, b) => b.meetDate.compareTo(a.meetDate));
    return sorted.first;
  }

  static RaceIntelligencePlan _planForGoal({
    required SwimGoal goal,
    required SwimmerProfile? profile,
    required UsaMotivationalStandardsCatalog catalog,
    required List<RaceLog> pbs,
    MeetResult? recentMeet,
  }) {
    final matchingPb = _findMatchingPb(pbs, goal.event);
    final cut = matchingPb == null
        ? null
        : MotivationalCut.labelForSwim(
            catalog: catalog,
            profile: profile,
            stroke: matchingPb.stroke,
            distance: matchingPb.distance,
            course: matchingPb.course,
            timeSeconds: matchingPb.timeSeconds,
          );

    final gap = matchingPb != null && goal.goalTime > 0
        ? (matchingPb.timeSeconds - goal.goalTime).clamp(-99.0, 99.0)
        : null;

    return RaceIntelligencePlan(
      event: goal.event,
      course: goal.course,
      headline: 'Target: ${SwimTime.fromSeconds(goal.goalTime)} ${goal.course}',
      strategy: gap != null && gap > 0
          ? 'You need ${SwimTime.fromSeconds(gap)} faster to hit goal time. '
              'Negative-split the second half and protect your start.'
          : 'Race to your process goals — strong breakout, tempo, and finish.',
      raceTips: [
        'Pre-race: visualize start reaction and first underwater.',
        'Race plan: build through middle 50, accelerate into finish.',
        if (cut != null) 'Current motivational level on this event: $cut.',
        if (recentMeet != null)
          'Last meet (${recentMeet.meetName}): review what worked in ${recentMeet.event}.',
        'Post-race: log splits and notes in Meets tab within 24 hours.',
      ],
      goalTime: SwimTime.fromSeconds(goal.goalTime),
      currentPb: matchingPb != null
          ? SwimTime.fromSeconds(matchingPb.timeSeconds)
          : goal.currentTime != null
              ? SwimTime.fromSeconds(goal.currentTime!)
              : null,
      standardsTarget: cut,
      targetDate: goal.targetDate,
      meetName: recentMeet?.meetName,
    );
  }

  static RaceIntelligencePlan _planForMeetResult({
    required MeetResult result,
    required SwimmerProfile? profile,
    required UsaMotivationalStandardsCatalog catalog,
    required List<RaceLog> pbs,
  }) {
    final matchingPb = _findMatchingPb(pbs, result.event);
    final cut = matchingPb == null
        ? null
        : MotivationalCut.labelForSwim(
            catalog: catalog,
            profile: profile,
            stroke: matchingPb.stroke,
            distance: matchingPb.distance,
            course: matchingPb.course,
            timeSeconds: matchingPb.timeSeconds,
          );

    return RaceIntelligencePlan(
      event: result.event,
      course: result.course,
      headline: '${result.meetName} · ${SwimTime.fromSeconds(result.swimTime)}',
      strategy:
          'Use this result as your baseline. Race Intelligence adjusts tips '
          'when you add the next goal or upcoming meet date.',
      raceTips: [
        'Compare this swim to your training PB and goal pace.',
        if (cut != null) 'Motivational cut reference: $cut.',
        'Note one thing to repeat and one thing to fix before the next meet.',
        if (result.notes?.trim().isNotEmpty == true)
          'Prior meet note: ${result.notes!.trim()}',
      ],
      currentPb: SwimTime.fromSeconds(result.swimTime),
      standardsTarget: cut,
      targetDate: result.meetDate,
      meetName: result.meetName,
    );
  }

  static bool _eventsLooselyMatch(String left, String right) {
    final a = left.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final b = right.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return a.contains(b) || b.contains(a);
  }

  static RaceLog? _findMatchingPb(List<RaceLog> pbs, String event) {
    for (final pb in pbs) {
      if (_eventsLooselyMatch(pb.event, event)) return pb;
    }
    return null;
  }

  static List<String> _meetDayTips(SwimGoal? nextGoal, MeetResult? recentMeet) {
    return [
      'Arrive early — 30–45 min before your race for full warmup.',
      'Hydrate and fuel 2–3 hours before racing; light snack 60 min out.',
      if (nextGoal != null)
        'Goal race ${nextGoal.event}: target ${SwimTime.fromSeconds(nextGoal.goalTime)}.',
      'Between races: stay loose, review one cue from AI Coach priorities.',
      if (recentMeet != null)
        'Last meet reference: ${recentMeet.meetName} (${recentMeet.event}).',
      'Log every race in Meets tab while details are fresh.',
    ];
  }

  static List<String> _warmupTips(String? primaryStroke) {
    final stroke = primaryStroke?.trim();
    return [
      '400 easy swim → 4×50 drill / swim by 25.',
      '6×25 build to race pace with :15 rest.',
      if (stroke != null && stroke.isNotEmpty)
        '$stroke prep: 4×25 race skill (breakout, tempo, or finish).',
      '2×25 all-out from the blocks 20–30 min before your heat.',
      'Stay in routine — same warmup order you used in practice.',
    ];
  }
}
