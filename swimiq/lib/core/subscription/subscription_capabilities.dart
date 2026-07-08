import 'package:flutter/foundation.dart';

import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';

/// Feature access derived from subscription state (local scaffold until Store billing).
class SubscriptionCapabilities {
  SubscriptionCapabilities._();

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
    return false;
  }

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

  static String eliteGateMessage(SubscriptionState state) {
    if (state.isCoachTrialActive && !state.hasCoachElitePeek) {
      if (state.coachAiAnalysesUsed >=
          SubscriptionCatalog.coachEliteAnalysisLimit) {
        return 'Coach Elite sneak peek: ${SubscriptionCatalog.coachEliteAnalysisLimit} '
            'SwimIQ AI analyses used. Upgrade to Elite for unlimited AI coaching.';
      }
      return 'Coach Elite sneak peek ended. Upgrade to Elite for Video Lab AI, '
          'Race Intelligence, and nutrition plans.';
    }
    return 'SwimIQ AI coaching is included with Elite. Start a trial or upgrade '
        'from Plans & billing in Settings.';
  }

  static String upgradeUnavailableMessage(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android =>
        'Paid upgrades on Android launch with Google Play billing soon.',
      TargetPlatform.iOS =>
        'Paid upgrades on iPhone launch with App Store billing soon.',
      _ =>
        'Upgrade from Plans & billing in Settings or subscribe on swimiqapp.com.',
    };
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
