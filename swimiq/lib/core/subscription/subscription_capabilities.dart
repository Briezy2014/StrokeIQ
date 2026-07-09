import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';
import '../../providers/app_providers.dart';

/// Feature access derived from subscription state.
class SubscriptionCapabilities {
  SubscriptionCapabilities._();

  static bool meetsMinimumTier(
    SubscriptionState state,
    SubscriptionTier minimum,
  ) {
    switch (minimum) {
      case SubscriptionTier.basic:
      case SubscriptionTier.trial:
        return true;
      case SubscriptionTier.pro:
      case SubscriptionTier.coach:
        return hasProAccess(state);
      case SubscriptionTier.elite:
        return hasEliteAccess(state);
    }
  }

  static bool hasProAccess(SubscriptionState state) {
    switch (state.effectiveTier) {
      case SubscriptionTier.elite:
      case SubscriptionTier.pro:
      case SubscriptionTier.coach:
        return true;
      case SubscriptionTier.trial:
        return state.isTrialActive;
      case SubscriptionTier.basic:
        return false;
    }
  }

  static bool hasEliteAccess(SubscriptionState state) {
    if (state.isDemoMaster) return true;
    if (state.effectiveTier == SubscriptionTier.elite) return true;
    if (state.isTrialActive) return true;
    if (state.isCoachTrialActive && state.hasCoachElitePeek) return true;
    return false;
  }

  // ── Basic (foundation) ──────────────────────────────────────────────

  static bool canUseTrainingLog(SubscriptionState state) => true;

  static bool canUseAddSession(SubscriptionState state) => true;

  static bool canUseBasicDashboard(SubscriptionState state) => true;

  static bool canAccessGoals(SubscriptionState state) => true;

  static bool canAccessBasicPersonalBests(SubscriptionState state) => true;

  static bool canAccessWeeklyProgressReport(SubscriptionState state) => true;

  static bool canAccessDashboardGamification(SubscriptionState state) => true;

  static bool canAccessProgressCharts(SubscriptionState state) => true;

  // ── Pro (competitive tools) ─────────────────────────────────────────

  static bool canUseProFeatures(SubscriptionState state) => hasProAccess(state);

  static bool canAccessOfficialPbsAndStandards(SubscriptionState state) =>
      hasProAccess(state);

  /// Legacy alias — official meet PBs & USA standards.
  static bool canAccessPersonalBests(SubscriptionState state) =>
      canAccessOfficialPbsAndStandards(state);

  static bool canAccessMeetResults(SubscriptionState state) =>
      hasProAccess(state);

  static bool canAccessPassport(SubscriptionState state) => hasProAccess(state);

  static bool canAccessVideoLab(SubscriptionState state) => hasProAccess(state);

  static bool canAccessAiDrylandCoach(SubscriptionState state) =>
      hasProAccess(state);

  static bool canAccessMotivationalCuts(SubscriptionState state) =>
      hasProAccess(state);

  // ── Elite (AI performance intelligence) ─────────────────────────────

  static bool canRunSwimIqAiAnalysis(SubscriptionState state) {
    if (!hasEliteAccess(state)) return false;
    if (state.isCoachTrialActive && state.hasCoachElitePeek) {
      return state.coachAiAnalysesUsed <
          SubscriptionCatalog.coachEliteAnalysisLimit;
    }
    return true;
  }

  static bool canAccessRecruitingHub(SubscriptionState state) => hasProAccess(state);

  static bool canAccessRecruitingIntelligence(SubscriptionState state) =>
      hasEliteAccess(state);

  static bool canUseRaceIntelligence(SubscriptionState state) =>
      hasEliteAccess(state);

  static bool canAccessAiPerformanceReports(SubscriptionState state) =>
      hasEliteAccess(state);

  static SubscriptionTier minimumTierForHomeTab(int tabIndex) {
    switch (tabIndex) {
      case HomeTab.dashboard:
      case HomeTab.personalBests:
      case HomeTab.trainingLog:
      case HomeTab.goals:
        return SubscriptionTier.basic;
      case HomeTab.meetResults:
      case HomeTab.videoLab:
      case HomeTab.passport:
        return SubscriptionTier.pro;
      default:
        return SubscriptionTier.basic;
    }
  }

  static bool canAccessHomeTab(int tabIndex, SubscriptionState? state) {
    if (state == null) {
      return minimumTierForHomeTab(tabIndex) == SubscriptionTier.basic;
    }
    return meetsMinimumTier(state, minimumTierForHomeTab(tabIndex));
  }

  static String proGateMessage({String feature = 'This feature'}) =>
      '$feature is included with SwimIQ Pro — official PBs, meet results, USA '
      'standards, Athlete Passport, Video Lab, and AI Dryland Coach. Most '
      'competitive families start here.';

  static String eliteGateMessage(SubscriptionState state) {
    if (state.isCoachTrialActive && !state.hasCoachElitePeek) {
      if (state.coachAiAnalysesUsed >=
          SubscriptionCatalog.coachEliteAnalysisLimit) {
        return 'Coach Elite sneak peek: ${SubscriptionCatalog.coachEliteAnalysisLimit} '
            'SwimIQ AI analyses used. Upgrade to Elite for unlimited AI coaching.';
      }
      return 'Coach Elite sneak peek ended. Upgrade to Elite for AI Stroke Analysis, '
          'Race Intelligence, and AI performance reports.';
    }
    return 'SwimIQ Elite unlocks AI Stroke Analysis, Race Intelligence, AI performance '
        'reports, and personalized race strategy.';
  }

  static String coachPreviewSummary(SubscriptionState state) {
    if (!state.isCoachTrialActive) return '';
    final daysLeft = state.coachTrialDaysRemaining;
    if (state.hasCoachElitePeek) {
      final analysesLeft = SubscriptionCatalog.coachEliteAnalysisLimit -
          state.coachAiAnalysesUsed;
      return 'Coach preview · Pro access · Elite AI sneak peek '
          '($analysesLeft AI analyses left · $daysLeft days remaining)';
    }
    return 'Coach preview · Pro access · $daysLeft days remaining '
        '(Elite AI sneak peek ended — upgrade to evaluate further)';
  }
}
