import '../../data/models/meet_result.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/usa_motivational_standards_catalog.dart';
import '../utils/goal_progress_analytics.dart';
import '../utils/motivational_cut.dart';
import '../utils/swim_analytics.dart';
import '../utils/swim_time.dart';
import '../utils/swimiq_standards_profile.dart';
import 'meet_history_analytics.dart';
import 'recruiting_card_insights.dart';

/// One sales-ready Career Highlights card.
class CareerHighlightItem {
  const CareerHighlightItem({
    required this.id,
    required this.title,
    required this.value,
    required this.iconName,
    required this.significance,
    this.subtitle,
    this.detail,
  });

  final String id;
  final String title;
  final String value;
  final String? subtitle;
  final String? detail;
  /// Material icon key resolved in the UI.
  final String iconName;
  /// Higher = show first.
  final int significance;
}

/// Recruiter-facing Career Highlights built from existing SwimIQ data.
class CareerHighlightsSummary {
  const CareerHighlightsSummary({
    required this.cards,
    required this.meets,
    required this.races,
    required this.lifetimePbs,
    required this.yearsCompetitive,
    required this.highestCut,
    required this.swimIqScore,
    required this.swimIqRating,
    required this.improvementTrendPercent,
    required this.history,
  });

  final List<CareerHighlightItem> cards;
  final int meets;
  final int races;
  final int lifetimePbs;
  final int? yearsCompetitive;
  final String? highestCut;
  final int swimIqScore;
  final String swimIqRating;
  final double? improvementTrendPercent;
  final MeetHistorySummary history;

  bool get hasAnything =>
      cards.isNotEmpty || races > 0 || lifetimePbs > 0 || history.totalSwims > 0;
}

class CareerHighlightsBuilder {
  const CareerHighlightsBuilder._();

  static CareerHighlightsSummary build({
    required List<MeetResult> meetResults,
    required List<PersonalBestEntry> personalBests,
    required List<SwimGoal> goals,
    required List<RaceLog> raceLogs,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
    required int swimIqScore,
    required List<SwimVideoAnalysis> videoAnalyses,
  }) {
    final history = MeetHistoryAnalytics.build(
      meetResults: meetResults,
      personalBests: personalBests,
    );
    final cards = <CareerHighlightItem>[];

    final cutInfo = _highestCutWithEvent(
      personalBests: personalBests,
      catalog: catalog,
      profile: profile,
    );
    final achievement = _careerAchievement(
      highestCut: cutInfo?.cut,
      meetResults: meetResults,
    );
    if (achievement != null) cards.add(achievement);

    if (cutInfo != null) {
      cards.add(
        CareerHighlightItem(
          id: 'usa_standard',
          title: 'Highest USA Standard',
          value: cutInfo.cut,
          subtitle: cutInfo.eventLabel,
          detail:
              '${cutInfo.cut} motivational standard on ${cutInfo.eventLabel}. '
              'This is the recruiting cut coaches scan first.',
          iconName: 'military_tech',
          significance: 95,
        ),
      );
    }

    final drop = _biggestTimeDrop(meetResults);
    if (drop != null) {
      cards.add(
        CareerHighlightItem(
          id: 'biggest_drop',
          title: 'Biggest Lifetime Drop',
          value: drop.value,
          subtitle: drop.eventLabel,
          detail: drop.detail,
          iconName: 'trending_down',
          significance: 90,
        ),
      );
      cards.add(
        CareerHighlightItem(
          id: 'most_improved',
          title: 'Most Improved Event',
          value: drop.eventLabel,
          subtitle: drop.value,
          detail:
              '${drop.eventLabel} shows the largest long-term improvement '
              '(${drop.value}).',
          iconName: 'rocket_launch',
          significance: 82,
        ),
      );
    }

    if (swimIqScore > 0) {
      final rating = swimIqRatingLabel(swimIqScore);
      cards.add(
        CareerHighlightItem(
          id: 'swimiq_rating',
          title: 'SwimIQ Performance Rating',
          value: rating,
          subtitle: 'Score $swimIqScore',
          detail:
              'SwimIQ rating $rating from score $swimIqScore — '
              'built from meets, training, goals, and video activity.',
          iconName: 'speed',
          significance: 88,
        ),
      );
    }

    if (personalBests.isNotEmpty) {
      cards.add(
        CareerHighlightItem(
          id: 'lifetime_pbs',
          title: 'Lifetime Personal Bests',
          value: '${personalBests.length}',
          subtitle: personalBests.length == 1
              ? 'Official event best'
              : 'Official event bests',
          detail:
              '${personalBests.length} lifetime personal bests across '
              'official meet events.',
          iconName: 'emoji_events',
          significance: 70,
        ),
      );
    }

    final goalRate = _goalCompletion(
      goals: goals,
      raceLogs: raceLogs,
      meetResults: meetResults,
      catalog: catalog,
      profile: profile,
    );
    if (goalRate != null) cards.add(goalRate);

    final tech = _technicalStrength(videoAnalyses);
    if (tech != null) cards.add(tech);

    cards.sort((a, b) => b.significance.compareTo(a.significance));

    final years = _yearsCompetitive(meetResults);
    final trend = _improvementTrendPercent(meetResults);

    return CareerHighlightsSummary(
      cards: cards,
      meets: history.realMeetCount,
      races: history.totalSwims,
      lifetimePbs: personalBests.length,
      yearsCompetitive: years,
      highestCut: cutInfo?.cut,
      swimIqScore: swimIqScore,
      swimIqRating: swimIqRatingLabel(swimIqScore),
      improvementTrendPercent: trend,
      history: history,
    );
  }

  static String swimIqRatingLabel(int score) {
    if (score >= 850) return 'National Elite';
    if (score >= 750) return 'Elite';
    if (score >= 650) return 'Advanced';
    if (score >= 550) return 'Competitive';
    if (score > 0) return 'Developing';
    return 'Getting Started';
  }

  static CareerHighlightItem? _careerAchievement({
    required String? highestCut,
    required List<MeetResult> meetResults,
  }) {
    final badge = highestCut == null || highestCut.isEmpty
        ? null
        : RecruitingCardInsights.from(
            highestCut: highestCut,
            topEvents: const [],
            swimIqScore: 0,
          ).achievementBadge;

    final meetChamp = _highestChampionshipMeet(meetResults);

    // Prefer a real cut-derived badge; fall back to championship meet level.
    final value = (badge == null || badge == 'Rising Athlete')
        ? meetChamp
        : badge;
    if (value == null) return null;

    return CareerHighlightItem(
      id: 'career_achievement',
      title: 'Career Best Achievement',
      value: value,
      subtitle: meetChamp != null && badge != null && badge != meetChamp
          ? 'Seen in $meetChamp meets'
          : 'From standards & meet history',
      detail:
          '$value — auto-highlighted from USA motivational standards and '
          'championship-style meet names in the log.',
      iconName: 'workspace_premium',
      significance: 100,
    );
  }

  /// Highest championship-style meet level inferred from meet names.
  static String? _highestChampionshipMeet(List<MeetResult> meetResults) {
    var bestRank = 0;
    String? bestLabel;
    for (final swim in meetResults) {
      if (MeetHistoryAnalytics.isSyntheticMeetName(swim.meetName)) continue;
      final name = swim.meetName.toLowerCase();
      final hit = _championshipRank(name);
      if (hit != null && hit.rank > bestRank) {
        bestRank = hit.rank;
        bestLabel = hit.label;
      }
    }
    return bestLabel;
  }

  static ({int rank, String label})? _championshipRank(String meetNameLower) {
    if (meetNameLower.contains('national') &&
        !meetNameLower.contains('junior national')) {
      return (rank: 6, label: 'Nationals');
    }
    if (meetNameLower.contains('futures')) {
      return (rank: 5, label: 'Futures');
    }
    if (meetNameLower.contains('sectional')) {
      return (rank: 4, label: 'Sectionals');
    }
    if (meetNameLower.contains('zone')) {
      return (rank: 3, label: 'Zone Championship');
    }
    if (meetNameLower.contains('junior olympic') ||
        RegExp(r'\bjo\b').hasMatch(meetNameLower) ||
        meetNameLower.contains('junior national')) {
      return (rank: 2, label: 'Junior Olympics');
    }
    if (meetNameLower.contains('state')) {
      return (rank: 1, label: 'State Championship');
    }
    return null;
  }

  static ({String cut, String eventLabel})? _highestCutWithEvent({
    required List<PersonalBestEntry> personalBests,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
  }) {
    if (personalBests.isEmpty) return null;
    if (!SwimIqStandardsProfile.isReady(profile)) return null;

    final spotlight = SwimAnalytics.spotlightPersonalBest(
      personalBests: personalBests,
      catalog: catalog,
      profile: profile,
    );
    if (spotlight == null) return null;
    final cut = MotivationalCut.forSwim(
      catalog: catalog,
      profile: profile,
      stroke: spotlight.stroke,
      distance: spotlight.distance,
      course: spotlight.course,
      timeSeconds: spotlight.timeSeconds,
    );
    if (cut == null) return null;
    return (
      cut: cut,
      eventLabel:
          '${spotlight.displayTitle} ${spotlight.formattedTime} (${spotlight.course})',
    );
  }

  static ({String eventLabel, String value, String detail})? _biggestTimeDrop(
    List<MeetResult> meetResults,
  ) {
    final byEvent = <String, List<MeetResult>>{};
    for (final result in meetResults) {
      final key = '${result.event} (${result.course})';
      byEvent.putIfAbsent(key, () => []).add(result);
    }

    String? bestKey;
    double bestDrop = 0;
    MeetResult? first;
    MeetResult? best;

    for (final entry in byEvent.entries) {
      final swims = [...entry.value]
        ..sort((a, b) => a.meetDate.compareTo(b.meetDate));
      if (swims.length < 2) continue;
      final start = swims.first;
      final peak = swims.reduce(
        (a, b) => a.swimTime <= b.swimTime ? a : b,
      );
      final drop = start.swimTime - peak.swimTime;
      if (drop > bestDrop + 0.005) {
        bestDrop = drop;
        bestKey = entry.key;
        first = start;
        best = peak;
      }
    }

    if (bestKey == null || first == null || best == null || bestDrop <= 0) {
      return null;
    }

    final gap = SwimTime.fromSeconds(bestDrop);
    return (
      eventLabel: bestKey,
      value: '-$gap',
      detail:
          '$bestKey improved from ${SwimTime.fromSeconds(first.swimTime)} '
          'to ${SwimTime.fromSeconds(best.swimTime)} (−$gap).',
    );
  }

  static CareerHighlightItem? _goalCompletion({
    required List<SwimGoal> goals,
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
  }) {
    if (goals.isEmpty) return null;
    final snapshots = GoalProgressAnalytics.allSnapshots(
      goals: goals,
      raceLogs: raceLogs,
      meetResults: meetResults,
      catalog: catalog,
      profile: profile,
    );
    if (snapshots.isEmpty) return null;
    final achieved =
        snapshots.where((s) => s.status == GoalProgressStatus.achieved).length;
    final total = snapshots.length;
    final pct = ((achieved / total) * 100).round();
    return CareerHighlightItem(
      id: 'goal_rate',
      title: 'Goal Completion Rate',
      value: '$achieved of $total',
      subtitle: '$pct% season goals hit',
      detail:
          '$achieved of $total goals achieved ($pct%). '
          'Keep logging meets so goal cards stay current.',
      iconName: 'flag',
      significance: 75,
    );
  }

  static CareerHighlightItem? _technicalStrength(
    List<SwimVideoAnalysis> analyses,
  ) {
    if (analyses.isEmpty) return null;
    final sorted = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    final latest = sorted.first;
    final pro = latest.coachingSections.entries
        .where((e) => e.key.toLowerCase().contains('quick pro'))
        .map((e) => e.value.trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final strengths = latest.strengths.trim();
    final raw = pro.isNotEmpty ? pro : strengths;
    if (raw.isEmpty) return null;

    final label = _mapTechnicalLabel(raw);
    return CareerHighlightItem(
      id: 'technical_strength',
      title: 'Technical Strength',
      value: label,
      subtitle: 'From latest race video AI',
      detail: raw.length > 220 ? '${raw.substring(0, 220)}…' : raw,
      iconName: 'fitness_center',
      significance: 78,
    );
  }

  static String _mapTechnicalLabel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('underwater') || lower.contains('dolphin')) {
      return 'Elite Underwaters';
    }
    if (lower.contains('turn')) return 'Excellent Turns';
    if (lower.contains('finish') || lower.contains('touch')) {
      return 'Powerful Finish';
    }
    if (lower.contains('breakout')) return 'Exceptional Breakouts';
    if (lower.contains('tempo') || lower.contains('rhythm')) {
      return 'Strong Tempo Control';
    }
    if (lower.contains('stroke length') || lower.contains('dps')) {
      return 'Efficient Stroke Length';
    }
    if (lower.contains('body line') || lower.contains('hips')) {
      return 'Strong Body Line';
    }
    // Short first sentence / clause as fallback.
    final clean = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(RegExp(r'[.!•]'))
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => 'Race Strength');
    if (clean.length <= 36) return clean;
    return '${clean.substring(0, 34)}…';
  }

  static int? _yearsCompetitive(List<MeetResult> meetResults) {
    final dates = meetResults
        .where((r) => !MeetHistoryAnalytics.isSyntheticMeetName(r.meetName))
        .map((r) => r.meetDate)
        .toList();
    if (dates.isEmpty) return null;
    dates.sort();
    final years = DateTime.now().difference(dates.first).inDays / 365.25;
    if (years < 0.5) return 1;
    return years.ceil().clamp(1, 20);
  }

  static double? _improvementTrendPercent(List<MeetResult> meetResults) {
    final byEvent = <String, List<MeetResult>>{};
    for (final result in meetResults) {
      final key = '${result.event}|${result.course}';
      byEvent.putIfAbsent(key, () => []).add(result);
    }
    final drops = <double>[];
    for (final swims in byEvent.values) {
      if (swims.length < 2) continue;
      final ordered = [...swims]..sort((a, b) => a.meetDate.compareTo(b.meetDate));
      final first = ordered.first.swimTime;
      final best = ordered
          .map((s) => s.swimTime)
          .reduce((a, b) => a <= b ? a : b);
      if (first <= 0) continue;
      final pct = ((first - best) / first) * 100;
      if (pct > 0) drops.add(pct);
    }
    if (drops.isEmpty) return null;
    final avg = drops.reduce((a, b) => a + b) / drops.length;
    return double.parse(avg.toStringAsFixed(1));
  }
}
