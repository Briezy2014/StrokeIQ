import '../../core/utils/swim_analytics.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../core/utils/swimiq_gender.dart';
import '../../data/models/meet_result.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_goal.dart';
import '../../data/models/video_models.dart';
import '../../data/models/swimmer_profile.dart';
import 'swim_time.dart';

class PassportSnapshot {
  const PassportSnapshot({
    required this.swimmerName,
    required this.displayName,
    required this.swimIqScore,
    required this.swimIqExplanation,
    required this.currentFocus,
    required this.highestCut,
    required this.nextMeet,
    required this.imxScore,
    required this.readiness,
    required this.nextFocus,
    required this.personalBests,
    required this.goalLines,
    required this.videoCount,
    required this.analysisCount,
    required this.latestAnalysisSummary,
    required this.latestAnalysisEvent,
    required this.usaStandardsSummary,
  });

  final String swimmerName;
  final String displayName;
  final int swimIqScore;
  final String swimIqExplanation;
  final String currentFocus;
  final String highestCut;
  final String nextMeet;
  final String imxScore;
  final String readiness;
  final String nextFocus;
  final List<String> personalBests;
  final List<String> goalLines;
  final int videoCount;
  final int analysisCount;
  final String latestAnalysisSummary;
  final String? latestAnalysisEvent;
  final String usaStandardsSummary;
}

class PassportMetrics {
  PassportMetrics._();

  static PassportSnapshot build({
    required String swimmerName,
    required SwimmerProfile? profile,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    required List<MeetResult> meetResults,
    required List<SwimVideo> videos,
    required List<SwimVideoAnalysis> videoAnalyses,
    required UsaMotivationalStandardsCatalog motivationalStandards,
  }) {
    final userVideos = videos.where((video) => video.isUserFacing).toList();
    final userVideoIds =
        userVideos.map((video) => video.id).whereType<String>().toSet();
    final userAnalyses = videoAnalyses
        .where(
          (analysis) =>
              analysis.swimVideoId != null &&
              userVideoIds.contains(analysis.swimVideoId),
        )
        .toList();

    final pbs = SwimAnalytics.personalBests(raceLogs);
    final swimIqScore = swimIqScoreValue(
      raceLogs: raceLogs,
      goals: goals,
    );

    return PassportSnapshot(
      swimmerName: swimmerName,
      displayName: _displayName(profile, swimmerName),
      swimIqScore: swimIqScore,
      swimIqExplanation: swimIqExplanation(
        score: swimIqScore,
        raceLogs: raceLogs,
        goals: goals,
        personalBestCount: pbs.length,
      ),
      currentFocus: currentFocus(
        profile: profile,
        goals: goals,
        videos: userVideos,
        analyses: userAnalyses,
      ),
      highestCut: highestCut(
        raceLogs: raceLogs,
        catalog: motivationalStandards,
        profile: profile,
      ),
      nextMeet: nextMeet(meetResults),
      imxScore: imxScore(raceLogs),
      readiness: readiness(
        raceLogs: raceLogs,
        goals: goals,
        videos: userVideos,
        analyses: userAnalyses,
        swimIqScore: swimIqScore,
      ),
      nextFocus: nextFocus(
        profile: profile,
        goals: goals,
        videos: userVideos,
        analyses: userAnalyses,
        raceLogs: raceLogs,
      ),
      personalBests: personalBestLines(pbs),
      goalLines: goalProgressLines(goals: goals, raceLogs: raceLogs),
      videoCount: userVideos.length,
      analysisCount: userAnalyses.length,
      latestAnalysisSummary: latestAnalysisSummary(
        analyses: userAnalyses,
        videos: userVideos,
      ),
      latestAnalysisEvent: latestAnalysisEvent(
        analyses: userAnalyses,
        videos: userVideos,
      ),
      usaStandardsSummary: usaStandardsSummary(
        catalog: motivationalStandards,
        profile: profile,
        personalBests: pbs,
      ),
    );
  }

  static int swimIqScoreValue({
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
  }) =>
      SwimAnalytics.calculateSwimIqScore(raceLogs: raceLogs, goals: goals);

  static String swimIqExplanation({
    required int score,
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    required int personalBestCount,
  }) {
    if (raceLogs.isEmpty) {
      return 'No SwimIQ score yet. Log swim sessions to start building your score.';
    }

    return 'Score $score from ${raceLogs.length} logged sessions, '
        '${goals.length} goals, and $personalBestCount personal bests.';
  }

  static String currentFocus({
    SwimmerProfile? profile,
    required List<SwimGoal> goals,
    required List<SwimVideo> videos,
    required List<SwimVideoAnalysis> analyses,
  }) {
    final favorite = profile?.favoriteEvent?.trim();
    if (favorite != null && favorite.isNotEmpty) return favorite;

    final primary = profile?.primaryStroke?.trim();
    if (primary != null && primary.isNotEmpty) return primary;

    if (goals.isNotEmpty) return goals.first.event;

    if (videos.isNotEmpty) return videos.first.eventLabel;

    final latest = _latestAnalysis(analyses);
    if (latest?.analysisJson?['event'] != null) {
      return latest!.analysisJson!['event'].toString();
    }

    return 'Add a favorite event in your passport profile';
  }

  static String highestCut({
    required List<RaceLog> raceLogs,
    required UsaMotivationalStandardsCatalog catalog,
    SwimmerProfile? profile,
  }) {
    if (raceLogs.isEmpty) return 'Log sessions to compare against cuts';

    final pbs = SwimAnalytics.personalBests(raceLogs);
    final ageGroup = SwimIqAgeGroup.fromProfile(profile);
    final gender = SwimIqGender.standardsGender(profile);
    String? bestLevel;

    for (final pb in pbs) {
      final level = catalog.highestCutForTime(
        stroke: pb.stroke,
        distance: pb.distance,
        course: pb.course,
        swimmerTime: pb.timeSeconds,
        ageGroup: ageGroup,
        gender: gender,
      );
      if (level != null) {
        if (bestLevel == null || _levelRank(level) < _levelRank(bestLevel)) {
          bestLevel = level;
        }
      }
    }

    return bestLevel ?? 'No motivational cut matched yet';
  }

  static String nextMeet(List<MeetResult> meetResults) {
    if (meetResults.isEmpty) return 'No meet results logged yet';
    final sorted = [...meetResults]
      ..sort((a, b) => b.meetDate.compareTo(a.meetDate));
    return sorted.first.meetName;
  }

  static String readiness({
    required List<RaceLog> raceLogs,
    required List<SwimGoal> goals,
    required List<SwimVideo> videos,
    required List<SwimVideoAnalysis> analyses,
    required int swimIqScore,
  }) {
    final hasRecent = raceLogs.isNotEmpty;
    final hasGoals = goals.isNotEmpty;
    final hasVideo = videos.isNotEmpty;
    final hasAnalysis = analyses.isNotEmpty;

    if (swimIqScore >= 800 && hasRecent && hasGoals) return 'Race Ready';
    if (hasAnalysis && hasGoals) return 'Coaching Active';
    if (swimIqScore >= 600) return 'Building';
    if (hasVideo || hasRecent) return 'Developing';
    return 'Getting Started';
  }

  static String nextFocus({
    SwimmerProfile? profile,
    required List<SwimGoal> goals,
    required List<SwimVideo> videos,
    required List<SwimVideoAnalysis> analyses,
    required List<RaceLog> raceLogs,
  }) {
    final latest = _latestAnalysis(analyses);
    if (latest != null && latest.topPriorities.isNotEmpty) {
      return latest.topPriorities.first;
    }

    if (goals.isNotEmpty) {
      return 'Work toward goal: ${goals.first.event}';
    }

    if (videos.isNotEmpty && analyses.isEmpty) {
      return 'Run AI analysis on ${videos.first.displayTitle}';
    }

    if (raceLogs.isEmpty) {
      return 'Log your first training session';
    }

    final favorite = profile?.favoriteEvent?.trim();
    if (favorite != null && favorite.isNotEmpty) {
      return 'Build volume toward $favorite';
    }

    return 'Add a goal or upload a race video for coaching focus';
  }

  static List<String> personalBestLines(List<RaceLog> pbs) {
    if (pbs.isEmpty) return const ['No personal bests logged yet.'];

    return pbs
        .take(6)
        .map(
          (pb) =>
              '${pb.distance} ${pb.stroke} (${pb.course}): ${SwimTime.fromSeconds(pb.timeSeconds)}',
        )
        .toList();
  }

  static List<String> goalProgressLines({
    required List<SwimGoal> goals,
    required List<RaceLog> raceLogs,
  }) {
    if (goals.isEmpty) return const ['No goals added yet.'];

    return goals.take(5).map((goal) {
      final best = _bestTimeForGoal(goal, raceLogs);
      final target = SwimTime.fromSeconds(goal.goalTime);
      final targetDate = _formatDate(goal.targetDate);

      if (best == null) {
        return '${goal.event} (${goal.course}) → target $target by $targetDate';
      }

      final gap = best - goal.goalTime;
      if (gap <= 0) {
        return '${goal.event} (${goal.course}) → goal met at ${SwimTime.fromSeconds(best)}';
      }

      return '${goal.event} (${goal.course}) → best ${SwimTime.fromSeconds(best)}, '
          'need ${SwimTime.fromSeconds(gap)} faster for $target';
    }).toList();
  }

  static String latestAnalysisSummary({
    required List<SwimVideoAnalysis> analyses,
    required List<SwimVideo> videos,
  }) {
    if (analyses.isEmpty) {
      if (videos.isEmpty) {
        return 'No video analyses yet. Upload a swim video in Video Lab.';
      }
      return 'Upload complete. Run AI analysis on your latest video.';
    }

    final latest = _latestAnalysis(analyses)!;
    final event = latest.analysisJson?['event']?.toString();
    final score = latest.overallScore;
    final firstLine = latest.summary.split('\n').first.trim();
    if (event != null) {
      return '$event · score $score/100 · $firstLine';
    }
    return 'Latest analysis score $score/100 · $firstLine';
  }

  static String? latestAnalysisEvent({
    required List<SwimVideoAnalysis> analyses,
    required List<SwimVideo> videos,
  }) {
    final latest = _latestAnalysis(analyses);
    if (latest == null) return null;

    final event = latest.analysisJson?['event']?.toString();
    if (event != null && event.isNotEmpty) return event;

    for (final video in videos) {
      if (video.id == latest.swimVideoId) return video.eventLabel;
    }
    return null;
  }

  static String usaStandardsSummary({
    required UsaMotivationalStandardsCatalog catalog,
    SwimmerProfile? profile,
    required List<RaceLog> personalBests,
  }) {
    if (personalBests.isEmpty) {
      return '${catalog.versionLabel} loaded. Log sessions to compare cuts.';
    }

    final highest = highestCut(
      raceLogs: personalBests,
      catalog: catalog,
      profile: profile,
    );
    final closest = _closestCutGap(
      personalBests: personalBests,
      catalog: catalog,
      profile: profile,
    );

    if (closest == null) {
      return 'Highest cut achieved: $highest.';
    }

    return 'Highest cut achieved: $highest. Next target: ${closest.eventLabel} '
        '(${closest.standardLevel}, ${SwimTime.fromSeconds(closest.timeSeconds)}).';
  }

  static String imxScore(List<RaceLog> raceLogs) {
    if (raceLogs.isEmpty) return 'No stroke data yet';
    final strokes = raceLogs.map((log) => log.stroke).toSet();
    if (strokes.length >= 4) return 'IMX tracked (${strokes.length} strokes)';
    return '${strokes.length}/4 IM strokes logged';
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

  static double? _bestTimeForGoal(SwimGoal goal, List<RaceLog> raceLogs) {
    double? best;
    for (final log in raceLogs) {
      if (log.timeSeconds <= 0) continue;
      final event = goal.event.toLowerCase();
      if (!event.contains('${log.distance}') ||
          !event.contains(log.stroke.toLowerCase())) {
        continue;
      }
      if (log.course != goal.course) continue;
      if (best == null || log.timeSeconds < best) {
        best = log.timeSeconds;
      }
    }
    return best ?? goal.currentTime;
  }

  static _ClosestCut? _closestCutGap({
    required List<RaceLog> personalBests,
    required UsaMotivationalStandardsCatalog catalog,
    SwimmerProfile? profile,
  }) {
    final ageGroup = SwimIqAgeGroup.fromProfile(profile);
    final gender = SwimIqGender.standardsGender(profile);
    _ClosestCut? closest;

    for (final pb in personalBests) {
      final event = catalog.eventFor(
        ageGroup: ageGroup,
        gender: gender,
        stroke: SwimStrokeUtils.canonical(pb.stroke),
        distance: pb.distance,
        course: pb.course,
      );
      if (event == null) continue;

      for (final entry in event.cuts.entries) {
        final cutTime = entry.value;
        if (pb.timeSeconds <= cutTime) continue;
        final gap = pb.timeSeconds - cutTime;
        if (closest == null || gap < closest.gapSeconds) {
          closest = _ClosestCut(
            eventLabel: event.event,
            standardLevel: entry.key,
            timeSeconds: cutTime,
            gapSeconds: gap,
          );
        }
      }
    }

    return closest;
  }

  static String _displayName(SwimmerProfile? profile, String swimmerName) {
    final preferred = profile?.preferredName?.trim();
    if (preferred != null && preferred.isNotEmpty) return preferred;

    final fullName = profile?.displayName.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    return swimmerName;
  }

  static String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  static int _levelRank(String level) {
    const order = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];
    return order.indexOf(level);
  }
}

class _ClosestCut {
  const _ClosestCut({
    required this.eventLabel,
    required this.standardLevel,
    required this.timeSeconds,
    required this.gapSeconds,
  });

  final String eventLabel;
  final String standardLevel;
  final double timeSeconds;
  final double gapSeconds;
}
