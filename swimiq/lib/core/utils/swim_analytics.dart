import '../../data/models/meet_result.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/swim_video.dart';
import '../../data/models/swim_video_analysis.dart';
import '../../data/models/swimmer_profile.dart';
import '../services/usa_motivational_standards_catalog.dart';
import 'motivational_cut.dart';
import 'swimiq_standards_profile.dart';
import 'swim_time.dart';

/// Business logic for personal bests and SwimIQ scoring.
class SwimAnalytics {
  SwimAnalytics._();

  static List<RaceLog> personalBests(List<RaceLog> logs) {
    final valid = logs.where((log) => log.timeSeconds > 0).toList();
    if (valid.isEmpty) return [];

    final bestByEvent = <String, RaceLog>{};
    for (final log in valid) {
      final key = '${log.stroke}|${log.distance}|${log.course}';
      final existing = bestByEvent[key];
      if (existing == null || log.timeSeconds < existing.timeSeconds) {
        bestByEvent[key] = log;
      }
    }

    final results = bestByEvent.values.toList()
      ..sort((a, b) {
        final strokeCompare = a.stroke.compareTo(b.stroke);
        if (strokeCompare != 0) return strokeCompare;
        return a.distance.compareTo(b.distance);
      });
    return results;
  }

  /// Best times from **meet results only** (official meet swims).
  static List<PersonalBestEntry> personalBestsFromMeets({
    required List<MeetResult> meetResults,
  }) {
    final bestByEvent = <String, PersonalBestEntry>{};

    for (final result in meetResults) {
      if (result.swimTime <= 0) continue;
      final entry = PersonalBestEntry.fromMeetResult(result);
      if (!entry.isValid) continue;
      _keepFastest(bestByEvent, entry);
    }

    final results = bestByEvent.values.toList()
      ..sort((a, b) {
        final strokeCompare = a.stroke.compareTo(b.stroke);
        if (strokeCompare != 0) return strokeCompare;
        return a.distance.compareTo(b.distance);
      });
    return results;
  }

  static void _keepFastest(
    Map<String, PersonalBestEntry> bestByEvent,
    PersonalBestEntry entry,
  ) {
    final existing = bestByEvent[entry.eventKey];
    if (existing == null || entry.timeSeconds < existing.timeSeconds) {
      bestByEvent[entry.eventKey] = entry;
    }
  }

  static PersonalBestEntry? spotlightPersonalBest({
    required List<PersonalBestEntry> personalBests,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
  }) {
    if (personalBests.isEmpty) return null;
    if (!SwimIqStandardsProfile.isReady(profile)) {
      return personalBests.first;
    }

    PersonalBestEntry? bestCutEntry;
    String? bestCutLevel;
    const levelOrder = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];

    for (final entry in personalBests) {
      final level = MotivationalCut.forSwim(
        catalog: catalog,
        profile: profile,
        stroke: entry.stroke,
        distance: entry.distance,
        course: entry.course,
        timeSeconds: entry.timeSeconds,
      );
      if (level == null) continue;

      if (bestCutLevel == null ||
          levelOrder.indexOf(level) < levelOrder.indexOf(bestCutLevel)) {
        bestCutLevel = level;
        bestCutEntry = entry;
      }
    }

    return bestCutEntry ?? personalBests.first;
  }

  static String highestMotivationalCut({
    required List<PersonalBestEntry> personalBests,
    required UsaMotivationalStandardsCatalog catalog,
    required SwimmerProfile? profile,
  }) {
    if (personalBests.isEmpty) {
      return 'Log meet results to compare against cuts';
    }
    if (!SwimIqStandardsProfile.isReady(profile)) {
      return SwimIqStandardsProfile.setupMessageShort;
    }

    const levelOrder = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];
    String? bestLevel;

    for (final entry in personalBests) {
      final level = MotivationalCut.forSwim(
        catalog: catalog,
        profile: profile,
        stroke: entry.stroke,
        distance: entry.distance,
        course: entry.course,
        timeSeconds: entry.timeSeconds,
      );
      if (level == null) continue;
      if (bestLevel == null ||
          levelOrder.indexOf(level) < levelOrder.indexOf(bestLevel)) {
        bestLevel = level;
      }
    }

    return bestLevel ?? 'No motivational cut matched yet';
  }

  static bool isNewPersonalBest({
    required List<RaceLog> previousLogs,
    required String stroke,
    required int distance,
    required String course,
    required double timeSeconds,
  }) {
    final matching = previousLogs.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == course &&
          log.timeSeconds > 0,
    );

    if (matching.isEmpty) return true;

    final previousBest = matching
        .map((log) => log.timeSeconds)
        .reduce((a, b) => a < b ? a : b);
    return timeSeconds < previousBest;
  }

  /// SwimIQ Score (0–1000).
  ///
  /// Rises with logged practices, meet/PB uploads, goals, and video work.
  /// Falls gently after several quiet days (inactivity decay) so the rope
  /// cools off without cratering from a normal rest day or two.
  static int calculateSwimIqScore({
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    List<MeetResult> meetResults = const [],
    List<SwimVideo> videos = const [],
    List<SwimVideoAnalysis> analyses = const [],
    DateTime? now,
  }) {
    final hasAnyActivity = raceLogs.isNotEmpty ||
        meetResults.isNotEmpty ||
        videos.isNotEmpty ||
        analyses.isNotEmpty;
    if (!hasAnyActivity) return 0;

    final clock = now ?? DateTime.now();
    final meetPbs = personalBestsFromMeets(meetResults: meetResults);
    final logPbs = personalBests(raceLogs);
    final pbCount = meetPbs.isNotEmpty ? meetPbs.length : logPbs.length;

    // Lifetime foundation (capped so older volume alone cannot freeze the score).
    var score = 350;
    score += _capped(raceLogs.length, 40) * 5; // max +200
    score += _capped(goals.length, 8) * 15; // max +120
    score += _capped(pbCount, 16) * 12; // max +192
    score += _capped(meetResults.length, 30) * 5; // max +150
    score += _capped(videos.length + analyses.length, 12) * 8; // max +96

    // Recent work (last 7 days) — using the app should move the rope up quickly.
    final weekAgo = clock.subtract(const Duration(days: 7));
    final recentSessions =
        raceLogs.where((log) => !log.date.isBefore(weekAgo)).length;
    final recentMeets =
        meetResults.where((meet) => !meet.meetDate.isBefore(weekAgo)).length;
    final recentVideos = videos
        .where(
          (video) =>
              video.createdAt != null && !video.createdAt!.isBefore(weekAgo),
        )
        .length;
    final recentAnalyses = analyses
        .where(
          (analysis) =>
              analysis.createdAt != null &&
              !analysis.createdAt!.isBefore(weekAgo),
        )
        .length;
    var recentBoost = recentSessions * 12 +
        recentMeets * 18 +
        recentVideos * 14 +
        recentAnalyses * 14;
    if (recentBoost > 150) recentBoost = 150;
    score += recentBoost;

    // Inactivity decay — rest days are normal for swimmers.
    // Grace: 3 quiet days (no drop). Then gentle cooling, never a freefall.
    final lastActive = lastActivityDate(
      raceLogs: raceLogs,
      meetResults: meetResults,
      videos: videos,
      analyses: analyses,
    );
    final preDecayScore = score;
    if (lastActive != null) {
      final quietDays =
          _dateOnly(clock).difference(_dateOnly(lastActive)).inDays;
      score -= _quietDayDecay(quietDays);
      // Soft floor: keep most of the earned score after a short rest.
      // Prevents 590 → 32 style cliffs from a couple quiet days.
      final floor = _quietScoreFloor(preDecayScore);
      if (score < floor) score = floor;
    }

    if (score < 0) return 0;
    if (score > 1000) return 1000;
    return score;
  }

  /// Points removed for [quietDays] since last activity (0 = active today).
  ///
  /// 0–3 quiet days: no decay (rest / travel / meet recovery).
  /// Days 4–10: −8 / day.
  /// Days 11+: −12 / day.
  /// Hard cap: −180 (was −350 at −25/day).
  static int _quietDayDecay(int quietDays) {
    if (quietDays <= 3) return 0;
    var decay = 0;
    // Days 4..10 inclusive → up to 7 days * 8 = 56
    final mildDays = (quietDays - 3).clamp(0, 7);
    decay += mildDays * 8;
    // Days 11+ → 12 pts each
    if (quietDays > 10) {
      decay += (quietDays - 10) * 12;
    }
    return decay > 180 ? 180 : decay;
  }

  /// Never erase the athlete's foundation after a short break.
  static int _quietScoreFloor(int preDecayScore) {
    if (preDecayScore <= 0) return 0;
    // Keep at least 70% of what they earned before quiet-day cooling.
    final floor = (preDecayScore * 0.70).round();
    // Athletes with real history shouldn't fall into the water overnight.
    if (preDecayScore >= 400 && floor < 280) return 280;
    return floor;
  }

  /// Most recent practice / meet / video / analysis date, if any.
  static DateTime? lastActivityDate({
    required List<RaceLog> raceLogs,
    List<MeetResult> meetResults = const [],
    List<SwimVideo> videos = const [],
    List<SwimVideoAnalysis> analyses = const [],
  }) {
    DateTime? latest;
    void consider(DateTime? value) {
      if (value == null) return;
      if (latest == null || value.isAfter(latest!)) latest = value;
    }

    for (final log in raceLogs) {
      consider(log.date);
    }
    for (final meet in meetResults) {
      consider(meet.meetDate);
    }
    for (final video in videos) {
      consider(video.createdAt);
    }
    for (final analysis in analyses) {
      consider(analysis.createdAt);
    }
    return latest;
  }

  static int _capped(int value, int max) => value > max ? max : value;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String bestTime(List<RaceLog> logs) {
    final times = logs.map((log) => log.timeSeconds).where((t) => t > 0);
    if (times.isEmpty) return '—';
    return SwimTime.fromSeconds(times.reduce((a, b) => a < b ? a : b));
  }

  static String averageTime(List<RaceLog> logs) {
    final times = logs.map((log) => log.timeSeconds).where((t) => t > 0);
    if (times.isEmpty) return '—';
    final sum = times.fold<double>(0, (a, b) => a + b);
    return SwimTime.fromSeconds(sum / times.length);
  }

  /// Best time for a goal event matching stroke, distance, and course.
  static double? bestTimeForGoal({
    required SwimGoal goal,
    required List<RaceLog> raceLogs,
  }) {
    final parts = goal.event.split(' ');
    if (parts.length < 2) return null;

    final distance = int.tryParse(parts.first);
    final stroke = parts.sublist(1).join(' ');
    if (distance == null) return null;

    final matching = raceLogs.where(
      (log) =>
          log.stroke == stroke &&
          log.distance == distance &&
          log.course == goal.course &&
          log.timeSeconds > 0,
    );

    if (matching.isEmpty) return null;
    return matching.map((log) => log.timeSeconds).reduce((a, b) => a < b ? a : b);
  }

  /// Seconds remaining to reach goal; negative means goal achieved.
  static double? secondsToGoal({
    required SwimGoal goal,
    required List<RaceLog> raceLogs,
  }) {
    final best = bestTimeForGoal(goal: goal, raceLogs: raceLogs);
    if (best == null) return null;
    return best - goal.goalTime;
  }
}
