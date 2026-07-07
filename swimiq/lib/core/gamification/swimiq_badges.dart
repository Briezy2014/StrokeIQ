import '../../core/utils/passport_metrics.dart';
import '../../data/models/meet_result.dart';
import '../../data/models/personal_best_entry.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swimmer_profile.dart';
import '../../data/models/video_models.dart';
import '../../data/models/swim_goal.dart';
import 'swimiq_daily_progress.dart';

class SwimIqBadge {
  const SwimIqBadge({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
    required this.isEarned,
  });

  final String id;
  final String emoji;
  final String label;
  final String description;
  final bool isEarned;
}

abstract final class SwimIqBadgeCatalog {
  static List<SwimIqBadge> evaluate({
    required SwimIqDailyProgress daily,
    required List<RaceLog> raceLogs,
    required List<MeetResult> meetResults,
    required List<SwimGoal> goals,
    required List<PersonalBestEntry> personalBests,
    required List<SwimVideo> videos,
    required List<SwimVideoAnalysis> analyses,
    required SwimmerProfile? profile,
    required PassportSnapshot snapshot,
  }) {
    final earned = <String>{
      if (raceLogs.isNotEmpty) 'first_splash',
      if (raceLogs.length >= 10) 'ten_sessions',
      if (daily.sessionsToday >= 1) 'daily_diver',
      if (daily.sessionsToday >= 2) 'double_session',
      if (daily.todayPoints >= 50) 'half_rope',
      if (daily.todayPoints >= 100) 'summit_splash',
      if (goals.isNotEmpty) 'goal_setter',
      if (goals.length >= 3) 'goal_stack',
      if (personalBests.isNotEmpty) 'pb_hunter',
      if (meetResults.isNotEmpty) 'meet_machine',
      if (daily.meetsToday >= 1) 'meet_day_fire',
      if (videos.isNotEmpty) 'video_star',
      if (analyses.isNotEmpty) 'ai_coach_fan',
      if (analyses.length >= 5) 'analysis_pro',
      if (snapshot.swimIqScore >= 600) 'score_builder',
      if (snapshot.swimIqScore >= 800) 'race_ready_club',
      if (snapshot.readiness == 'Race Ready') 'race_ready',
      if (_profileComplete(profile)) 'passport_pro',
      if (_hasMotivationalCut(snapshot.highestCut)) 'cut_chaser',
      if (_isTopCut(snapshot.highestCut)) 'cut_crusher',
      if (_streakDays(raceLogs) >= 3) 'three_day_streak',
      if (_streakDays(raceLogs) >= 7) 'week_warrior',
    };

    return _definitions
        .map(
          (badge) => SwimIqBadge(
            id: badge.id,
            emoji: badge.emoji,
            label: badge.label,
            description: badge.description,
            isEarned: earned.contains(badge.id),
          ),
        )
        .toList();
  }

  static const _definitions = [
    (
      id: 'first_splash',
      emoji: '💧',
      label: 'First Splash',
      description: 'Log your first training session.',
    ),
    (
      id: 'daily_diver',
      emoji: '🏊',
      label: 'Daily Diver',
      description: 'Train today and climb the rope.',
    ),
    (
      id: 'double_session',
      emoji: '⚡',
      label: 'Double Session',
      description: 'Log two sessions in one day.',
    ),
    (
      id: 'half_rope',
      emoji: '🪢',
      label: 'Half Rope',
      description: 'Earn 50+ daily SwimIQ climb points.',
    ),
    (
      id: 'summit_splash',
      emoji: '🏁',
      label: 'Summit Splash',
      description: 'Max out today\'s climb at 100 points.',
    ),
    (
      id: 'goal_setter',
      emoji: '🎯',
      label: 'Goal Setter',
      description: 'Create at least one swim goal.',
    ),
    (
      id: 'goal_stack',
      emoji: '🚩',
      label: 'Goal Stack',
      description: 'Track three or more goals.',
    ),
    (
      id: 'pb_hunter',
      emoji: '🏆',
      label: 'PB Hunter',
      description: 'Record a personal best.',
    ),
    (
      id: 'ten_sessions',
      emoji: '🔟',
      label: 'Ten Sessions',
      description: 'Log ten training sessions.',
    ),
    (
      id: 'meet_machine',
      emoji: '📋',
      label: 'Meet Machine',
      description: 'Add a meet result.',
    ),
    (
      id: 'meet_day_fire',
      emoji: '🔥',
      label: 'Meet Day Fire',
      description: 'Log a meet result today.',
    ),
    (
      id: 'video_star',
      emoji: '🎥',
      label: 'Video Star',
      description: 'Upload a Video Lab clip.',
    ),
    (
      id: 'ai_coach_fan',
      emoji: '🤖',
      label: 'AI Coach Fan',
      description: 'Run a SwimIQ AI analysis.',
    ),
    (
      id: 'analysis_pro',
      emoji: '🧠',
      label: 'Analysis Pro',
      description: 'Complete five AI analyses.',
    ),
    (
      id: 'score_builder',
      emoji: '📈',
      label: 'Score Builder',
      description: 'Reach SwimIQ Score 600+.',
    ),
    (
      id: 'race_ready_club',
      emoji: '💪',
      label: '800 Club',
      description: 'Reach SwimIQ Score 800+.',
    ),
    (
      id: 'race_ready',
      emoji: '🏁',
      label: 'Race Ready',
      description: 'Hit Race Ready status on your passport.',
    ),
    (
      id: 'passport_pro',
      emoji: '🪪',
      label: 'Passport Pro',
      description: 'Complete your Athlete Passport profile.',
    ),
    (
      id: 'cut_chaser',
      emoji: '🎖️',
      label: 'Cut Chaser',
      description: 'Earn any USA motivational cut.',
    ),
    (
      id: 'cut_crusher',
      emoji: '💎',
      label: 'Cut Crusher',
      description: 'Reach A cut or higher.',
    ),
    (
      id: 'three_day_streak',
      emoji: '🔥',
      label: '3-Day Streak',
      description: 'Train three days in a row.',
    ),
    (
      id: 'week_warrior',
      emoji: '👑',
      label: 'Week Warrior',
      description: 'Train seven days in a row.',
    ),
  ];

  static bool _profileComplete(SwimmerProfile? profile) {
    if (profile == null) return false;
    return profile.team?.trim().isNotEmpty == true &&
        profile.primaryStroke?.trim().isNotEmpty == true &&
        profile.coachName?.trim().isNotEmpty == true;
  }

  static bool _hasMotivationalCut(String cut) {
    const cuts = {'B', 'BB', 'A', 'AA', 'AAA', 'AAAA'};
    return cuts.contains(cut.trim().toUpperCase());
  }

  static bool _isTopCut(String cut) {
    const top = {'A', 'AA', 'AAA', 'AAAA'};
    return top.contains(cut.trim().toUpperCase());
  }

  static int _streakDays(List<RaceLog> raceLogs) {
    if (raceLogs.isEmpty) return 0;

    final days = raceLogs
        .map((log) => DateTime(log.date.year, log.date.month, log.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    var streak = 1;
    for (var i = 0; i < days.length - 1; i++) {
      if (days[i].difference(days[i + 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
