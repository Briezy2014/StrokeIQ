import '../../providers/swimmer_data_provider.dart';
import 'race_intelligence_service.dart';

class MeetDayChecklistItem {
  const MeetDayChecklistItem({
    required this.title,
    required this.detail,
    required this.timing,
  });

  final String title;
  final String detail;
  final String timing;
}

class MeetDayBrief {
  const MeetDayBrief({
    required this.headline,
    required this.summary,
    required this.checklist,
    required this.raceLineup,
    required this.warmupPlan,
    required this.betweenRacesTips,
    this.meetName,
    this.meetDate,
  });

  final String headline;
  final String summary;
  final List<MeetDayChecklistItem> checklist;
  final List<String> raceLineup;
  final List<String> warmupPlan;
  final List<String> betweenRacesTips;
  final String? meetName;
  final DateTime? meetDate;
}

/// Live race-day toolkit — warmup, lineup, and between-races checklist.
abstract final class MeetDayService {
  static MeetDayBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final intelligence = RaceIntelligenceService.build(
      data: data,
      swimmer: swimmer,
    );
    final now = DateTime.now();
    final upcomingGoals = data.goals
        .where((goal) => !goal.targetDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    final meetName = intelligence.nextMeetName ??
        (upcomingGoals.isNotEmpty ? 'Target meet' : 'Next meet');
    final meetDate = intelligence.nextMeetDate ??
        (upcomingGoals.isNotEmpty ? upcomingGoals.first.targetDate : null);

    final raceLineup = intelligence.racePlans
        .map((plan) {
          final goal = plan.goalTime != null ? ' · goal ${plan.goalTime}' : '';
          return '${plan.event} ${plan.course}$goal';
        })
        .toList();

    if (raceLineup.isEmpty) {
      final focus = data.passportSnapshot(swimmer).currentFocus;
      raceLineup.add('$focus — add goals with meet dates for a lineup');
    }

    final checklist = <MeetDayChecklistItem>[
      const MeetDayChecklistItem(
        title: 'Pack bag',
        detail: 'Suit, cap, goggles (backup pair), towels, warm-ups, snacks, water.',
        timing: 'Night before',
      ),
      const MeetDayChecklistItem(
        title: 'Confirm heat sheet',
        detail: 'Screenshot events and estimated swim times. Note first race.',
        timing: 'Morning of',
      ),
      MeetDayChecklistItem(
        title: 'Arrive & check in',
        detail: 'Find team area, confirm events with coach, set phone to silent.',
        timing: meetDate != null ? '90 min before first race' : 'On arrival',
      ),
      const MeetDayChecklistItem(
        title: 'Warm-up',
        detail: 'Easy swim, drill set, 2–4 race-pace builds, fast start from block.',
        timing: '45–60 min before first race',
      ),
      const MeetDayChecklistItem(
        title: 'Pre-race routine',
        detail: 'Visualize race plan, cap/goggles check, stay loose between events.',
        timing: '15 min before each race',
      ),
      const MeetDayChecklistItem(
        title: 'Cool down',
        detail: 'Easy 200–400 after each race unless long wait — ask coach.',
        timing: 'After each race',
      ),
    ];

    return MeetDayBrief(
      headline: 'Meet Day Mode',
      summary:
          'Your live race-day playbook — warmup timing, event lineup, and '
          'between-races recovery pulled from goals and Race Intelligence™.',
      checklist: checklist,
      raceLineup: raceLineup,
      warmupPlan: intelligence.warmupTips,
      betweenRacesTips: intelligence.meetDayTips,
      meetName: meetName,
      meetDate: meetDate,
    );
  }

  static String formatMeetDate(DateTime? date) {
    if (date == null) return 'Date TBD';
    return '${date.month}/${date.day}/${date.year}';
  }
}
