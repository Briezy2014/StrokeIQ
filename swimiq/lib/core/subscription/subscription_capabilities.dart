import '../constants/app_constants.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';
import '../../providers/app_providers.dart';

/// Feature access derived from subscription state.
class SubscriptionCapabilities {
  SubscriptionCapabilities._();

  static bool meetsMinimumTier(
    SubscriptionState state,
    SubscriptionTier minimum, {
    String? email,
  }) {
    if (AppConstants.unlockAllTabsForPreview) return true;
    if (SubscriptionService.isBuiltInEliteEmail(email)) return true;
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

  static bool hasProAccess(SubscriptionState state, {String? email}) {
    if (AppConstants.unlockAllTabsForPreview ||
        state.isDemoMaster ||
        SubscriptionService.isBuiltInEliteEmail(email)) {
      return true;
    }
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

  /// Pro tools for the signed-in user — master/founder/demo always true.
  static bool canUseProFeaturesForEmail(
    SubscriptionState? state,
    String? email,
  ) {
    if (SubscriptionService.isBuiltInEliteEmail(email)) return true;
    if (state == null) return false;
    return canUseProFeatures(state, email: email);
  }

  static bool hasEliteAccess(SubscriptionState state, {String? email}) {
    if (AppConstants.unlockAllTabsForPreview ||
        state.isDemoMaster ||
        SubscriptionService.isBuiltInEliteEmail(email)) {
      return true;
    }
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

  static bool canUseProFeatures(SubscriptionState state, {String? email}) =>
      hasProAccess(state, email: email);

  static bool canAccessOfficialPbsAndStandards(
    SubscriptionState state, {
    String? email,
  }) =>
      hasProAccess(state, email: email);

  /// Legacy alias — official meet PBs & USA standards.
  static bool canAccessPersonalBests(SubscriptionState state, {String? email}) =>
      canAccessOfficialPbsAndStandards(state, email: email);

  static bool canAccessMeetResults(SubscriptionState state, {String? email}) =>
      hasProAccess(state, email: email);

  static bool canAccessPassport(SubscriptionState state, {String? email}) =>
      hasProAccess(state, email: email);

  static bool canAccessVideoLab(SubscriptionState state, {String? email}) =>
      hasProAccess(state, email: email);

  static bool canAccessAiDrylandCoach(SubscriptionState state, {String? email}) =>
      hasProAccess(state, email: email);

  static bool canAccessMotivationalCuts(SubscriptionState state, {String? email}) =>
      hasProAccess(state, email: email);

  // ── Elite (AI performance intelligence) ─────────────────────────────

  static bool canRunSwimIqAiAnalysis(SubscriptionState state, {String? email}) {
    if (AppConstants.unlockAllTabsForPreview ||
        state.isDemoMaster ||
        SubscriptionService.isBuiltInEliteEmail(email)) {
      return true;
    }
    if (!hasEliteAccess(state, email: email)) return false;
    if (state.isCoachTrialActive && state.hasCoachElitePeek) {
      return state.coachAiAnalysesUsed <
          SubscriptionCatalog.coachEliteAnalysisLimit;
    }
    return true;
  }

  static bool canAccessRecruitingHub(SubscriptionState state, {String? email}) =>
      hasProAccess(state, email: email);

  static bool canAccessRecruitingIntelligence(
    SubscriptionState state, {
    String? email,
  }) =>
      hasEliteAccess(state, email: email);

  static bool canUseRaceIntelligence(SubscriptionState state, {String? email}) =>
      hasEliteAccess(state, email: email);

  static bool canAccessAiPerformanceReports(
    SubscriptionState state, {
    String? email,
  }) =>
      hasEliteAccess(state, email: email);

  static SubscriptionTier minimumTierForHomeTab(int tabIndex) {
    switch (tabIndex) {
      case HomeTab.dashboard:
      case HomeTab.personalBests:
      case HomeTab.trainingLog:
      case HomeTab.goals:
        return SubscriptionTier.basic;
      case HomeTab.videoLab:
      case HomeTab.passport:
        return SubscriptionTier.pro;
      default:
        return SubscriptionTier.basic;
    }
  }

  static bool canAccessHomeTab(
    int tabIndex,
    SubscriptionState? state, {
    String? email,
  }) {
    if (AppConstants.unlockAllTabsForPreview) return true;
    if (SubscriptionService.isBuiltInEliteEmail(email)) return true;
    if (state == null) {
      return minimumTierForHomeTab(tabIndex) == SubscriptionTier.basic;
    }
    return meetsMinimumTier(
      state,
      minimumTierForHomeTab(tabIndex),
      email: email,
    );
  }

  static String proGateMessage({String feature = 'This feature'}) =>
      '$feature is included with SwimIQ Pro — official PBs, meet results, '
      'motivational cuts, Athlete Passport, College Recruiting Hub, Video Lab, '
      'and AI Dryland Coach. The plan most competitive families choose.';

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
    return 'SwimIQ Elite unlocks AI Video Stroke Analysis (Gemini + MediaPipe), '
        'Race Intelligence, AI Performance Reports, race strategy, season insights, '
        'and AI Recruiting Intelligence.';
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
