import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';

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

  /// Casual swimmer / parent: log sessions, simple dashboard.
  static bool canUseTrainingLog(SubscriptionState state) => true;

  static bool canUseAddSession(SubscriptionState state) => true;

  static bool canUseBasicDashboard(SubscriptionState state) => true;

  /// Serious age-group: analytics, PBs, meets, goals, passport, video library.
  static bool canUseProFeatures(SubscriptionState state) => hasProAccess(state);

  static bool canAccessPersonalBests(SubscriptionState state) =>
      hasProAccess(state);

  static bool canAccessGoals(SubscriptionState state) => hasProAccess(state);

  static bool canAccessMeetResults(SubscriptionState state) =>
      hasProAccess(state);

  static bool canAccessPassport(SubscriptionState state) => hasProAccess(state);

  static bool canAccessVideoLab(SubscriptionState state) => hasProAccess(state);

  static bool canAccessDashboardGamification(SubscriptionState state) =>
      hasProAccess(state);

  /// High-performance: AI video, race intelligence, advanced planning.
  static bool canRunSwimIqAiAnalysis(SubscriptionState state) {
    if (!hasEliteAccess(state)) return false;
    if (state.isCoachTrialActive && state.hasCoachElitePeek) {
      return state.coachAiAnalysesUsed <
          SubscriptionCatalog.coachEliteAnalysisLimit;
    }
    return true;
  }

  static bool canUseRaceIntelligence(SubscriptionState state) =>
      hasEliteAccess(state);

  static SubscriptionTier minimumTierForHomeTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // dashboard
      case 2: // log
      case 3: // add
        return SubscriptionTier.basic;
      case 1: // PBs
      case 4: // goals
      case 5: // meets
      case 6: // video
      case 7: // passport
        return SubscriptionTier.pro;
      default:
        return SubscriptionTier.basic;
    }
  }

  static bool canAccessHomeTab(int tabIndex, SubscriptionState? state) {
    if (state == null) return true;
    return meetsMinimumTier(state, minimumTierForHomeTab(tabIndex));
  }

  static String proGateMessage({String feature = 'This feature'}) =>
      '$feature is included with SwimIQ Pro — analytics, goals, meet results, '
      'passport, and video library. Most families start here.';

  static String eliteGateMessage(SubscriptionState state) {
    if (state.isCoachTrialActive && !state.hasCoachElitePeek) {
      if (state.coachAiAnalysesUsed >=
          SubscriptionCatalog.coachEliteAnalysisLimit) {
        return 'Coach Elite sneak peek: ${SubscriptionCatalog.coachEliteAnalysisLimit} '
            'SwimIQ AI analyses used. Upgrade to Elite for unlimited AI coaching.';
      }
      return 'Coach Elite sneak peek ended. Upgrade to Elite for Video Lab AI, '
          'Race Intelligence, and advanced meet planning.';
    }
    return 'SwimIQ Elite unlocks AI video analysis, Race Intelligence, and '
        'advanced performance planning.';
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
