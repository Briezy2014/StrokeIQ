import '../../providers/swimmer_data_provider.dart';

class SeasonPhase {
  const SeasonPhase({
    required this.name,
    required this.focus,
    required this.volumeGuidance,
    required this.weeksRemaining,
    required this.progressPercent,
  });

  final String name;
  final String focus;
  final String volumeGuidance;
  final int weeksRemaining;
  final int progressPercent;
}

class SeasonArcBrief {
  const SeasonArcBrief({
    required this.headline,
    required this.summary,
    required this.currentPhase,
    required this.milestones,
    required this.coachNote,
  });

  final String headline;
  final String summary;
  final SeasonPhase currentPhase;
  final List<String> milestones;
  final String coachNote;
}

/// Season periodization arc — base, build, taper, championship windows.
abstract final class SeasonArcService {
  static SeasonArcBrief build({
    required SwimmerData data,
    required String swimmer,
  }) {
    final now = DateTime.now();
    final upcomingGoals = data.goals
        .where((goal) => !goal.targetDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    final nextChampionship = upcomingGoals.isNotEmpty
        ? upcomingGoals.first.targetDate
        : DateTime(now.year, 7, 15);

    final phase = _phaseForDate(now, nextChampionship);
    final weeksOut = nextChampionship.difference(now).inDays ~/ 7;

    final milestones = <String>[
      if (upcomingGoals.isNotEmpty)
        'Next goal: ${upcomingGoals.first.event} on ${_formatDate(upcomingGoals.first.targetDate)}',
      if (data.meetResults.isNotEmpty)
        'Last meet: ${data.passportSnapshot(swimmer).nextMeet}',
      'Current focus: ${data.passportSnapshot(swimmer).currentFocus}',
      '${data.raceLogs.length} sessions logged this season',
    ];

    return SeasonArcBrief(
      headline: 'Season arc — ${phase.name}',
      summary:
          'Where you are in the training year relative to your next championship '
          'target. Adjust volume and race pace work accordingly.',
      currentPhase: phase,
      milestones: milestones,
      coachNote: weeksOut <= 2
          ? 'Taper window — protect sleep, reduce yardage, sharpen race skills.'
          : weeksOut <= 6
              ? 'Build phase — race-pace sets and meet rehearsal swims.'
              : 'Base phase — aerobic volume and technique consistency.',
    );
  }

  static SeasonPhase _phaseForDate(DateTime now, DateTime championship) {
    final daysOut = championship.difference(now).inDays;
    final weeksOut = (daysOut / 7).ceil().clamp(0, 52);

    if (daysOut <= 14) {
      return SeasonPhase(
        name: 'Championship / Taper',
        focus: 'Race readiness, starts, turns, and mental prep.',
        volumeGuidance: 'Lower yardage · higher quality · full rest between races.',
        weeksRemaining: weeksOut,
        progressPercent: 95,
      );
    }
    if (daysOut <= 42) {
      return SeasonPhase(
        name: 'Build',
        focus: 'Race-pace work and meet rehearsal.',
        volumeGuidance: 'Moderate-high volume with targeted speed sets.',
        weeksRemaining: weeksOut,
        progressPercent: 70,
      );
    }
    if (daysOut <= 84) {
      return SeasonPhase(
        name: 'Pre-build',
        focus: 'Aerobic base and stroke efficiency.',
        volumeGuidance: 'Steady volume · drill emphasis · secondary events.',
        weeksRemaining: weeksOut,
        progressPercent: 45,
      );
    }
    return SeasonPhase(
      name: 'Base',
      focus: 'Foundation fitness and technique habits.',
      volumeGuidance: 'Consistent attendance · IM balance · dryland if available.',
      weeksRemaining: weeksOut,
      progressPercent: 25,
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}
