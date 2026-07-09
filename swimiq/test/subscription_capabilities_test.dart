import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/constants/founder_account_constants.dart';
import 'package:swimiq/core/models/subscription_plan.dart';
import 'package:swimiq/core/services/subscription_service.dart';
import 'package:swimiq/core/subscription/subscription_capabilities.dart';
import 'package:swimiq/providers/app_providers.dart';

void main() {
  test('coach preview grants elite peek then pro only', () {
    final started = DateTime.now().subtract(const Duration(days: 1));
    final state = SubscriptionState(
      tier: SubscriptionTier.basic,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: null,
      coachTrialEndsAt: DateTime.now().add(const Duration(days: 10)),
      coachTrialStartedAt: started,
      coachAiAnalysesUsed: 0,
      hasUsedTrial: true,
    );

    expect(state.hasCoachElitePeek, isTrue);
    expect(state.effectiveTier, SubscriptionTier.elite);
    expect(SubscriptionCapabilities.canRunSwimIqAiAnalysis(state), isTrue);
  });

  test('coach preview ends elite peek after analysis limit', () {
    final started = DateTime.now().subtract(const Duration(days: 1));
    final state = SubscriptionState(
      tier: SubscriptionTier.basic,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: null,
      coachTrialEndsAt: DateTime.now().add(const Duration(days: 10)),
      coachTrialStartedAt: started,
      coachAiAnalysesUsed: SubscriptionCatalog.coachEliteAnalysisLimit,
      hasUsedTrial: true,
    );

    expect(state.hasCoachElitePeek, isFalse);
    expect(state.effectiveTier, SubscriptionTier.pro);
    expect(SubscriptionCapabilities.canRunSwimIqAiAnalysis(state), isFalse);
  });

  test('legacy and new coach codes are accepted', () {
    expect(SubscriptionCatalog.isCoachAccessCode('COACH-EVAL-14'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('coach-trial-30'), isTrue);
    expect(SubscriptionCatalog.isCoachAccessCode('INVALID'), isFalse);
  });

  test('basic tier unlocks goals, pbs tab, log and dashboard', () {
    const state = SubscriptionState(
      tier: SubscriptionTier.basic,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: null,
      coachTrialEndsAt: null,
      coachTrialStartedAt: null,
      coachAiAnalysesUsed: 0,
      hasUsedTrial: true,
    );

    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.dashboard, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.personalBests, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.trainingLog, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.goals, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.meetResults, state), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.videoLab, state), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.passport, state), isFalse);
    expect(SubscriptionCapabilities.canAccessGoals(state), isTrue);
    expect(SubscriptionCapabilities.canAccessBasicPersonalBests(state), isTrue);
    expect(SubscriptionCapabilities.canAccessWeeklyProgressReport(state), isTrue);
    expect(SubscriptionCapabilities.canAccessDashboardGamification(state), isTrue);
    expect(SubscriptionCapabilities.canAccessOfficialPbsAndStandards(state), isFalse);
    expect(SubscriptionCapabilities.canAccessAiDrylandCoach(state), isFalse);
    expect(SubscriptionCapabilities.canRunSwimIqAiAnalysis(state), isFalse);
  });

  test('subscription loading locks pro tabs until loaded', () {
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.dashboard, null), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.goals, null), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.meetResults, null), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.videoLab, null), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.passport, null), isFalse);
  });

  test('pro tier unlocks competitive tools but not elite ai', () {
    const state = SubscriptionState(
      tier: SubscriptionTier.pro,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: null,
      coachTrialEndsAt: null,
      coachTrialStartedAt: null,
      coachAiAnalysesUsed: 0,
      hasUsedTrial: true,
      serverStatus: 'active',
    );

    expect(SubscriptionCapabilities.canUseProFeatures(state), isTrue);
    expect(SubscriptionCapabilities.canAccessOfficialPbsAndStandards(state), isTrue);
    expect(SubscriptionCapabilities.canAccessMeetResults(state), isTrue);
    expect(SubscriptionCapabilities.canAccessAiDrylandCoach(state), isTrue);
    expect(SubscriptionCapabilities.canRunSwimIqAiAnalysis(state), isFalse);
    expect(SubscriptionCapabilities.canUseRaceIntelligence(state), isFalse);
  });

  test('elite tier unlocks ai stroke analysis and race intelligence', () {
    const state = SubscriptionState(
      tier: SubscriptionTier.elite,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: null,
      coachTrialEndsAt: null,
      coachTrialStartedAt: null,
      coachAiAnalysesUsed: 0,
      hasUsedTrial: true,
      serverStatus: 'active',
    );

    expect(SubscriptionCapabilities.canUseProFeatures(state), isTrue);
    expect(SubscriptionCapabilities.canRunSwimIqAiAnalysis(state), isTrue);
    expect(SubscriptionCapabilities.canUseRaceIntelligence(state), isTrue);
    expect(SubscriptionCapabilities.canAccessAiPerformanceReports(state), isTrue);
  });

  test('founder emails are recognized', () {
    expect(FounderAccountConstants.isFounderEmail('briezy682014@gmail.com'), isTrue);
    expect(FounderAccountConstants.isFounderEmail('owner@swimiqapp.com'), isTrue);
    expect(FounderAccountConstants.isFounderEmail('random@gmail.com'), isFalse);
  });

  test('founder elite state unlocks all features', () {
    const state = SubscriptionState(
      tier: SubscriptionTier.elite,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: null,
      coachTrialEndsAt: null,
      coachTrialStartedAt: null,
      coachAiAnalysesUsed: 0,
      hasUsedTrial: true,
      serverStatus: 'active',
      isDemoMaster: true,
    );

    expect(SubscriptionCapabilities.canUseProFeatures(state), isTrue);
    expect(SubscriptionCapabilities.canRunSwimIqAiAnalysis(state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.videoLab, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(HomeTab.passport, state), isTrue);
  });

  test('plan catalog uses updated tier names and badges', () {
    final basic = SubscriptionCatalog.planFor(SubscriptionTier.basic);
    final pro = SubscriptionCatalog.planFor(SubscriptionTier.pro);
    final elite = SubscriptionCatalog.planFor(SubscriptionTier.elite);

    expect(basic.name, 'SwimIQ Basic');
    expect(basic.tagline, contains('foundation'));
    expect(pro.name, 'SwimIQ Pro');
    expect(pro.badgeLabel, 'Most Popular');
    expect(elite.name, 'SwimIQ Elite');
    expect(elite.badgeLabel, 'Advanced AI Performance');
    expect(elite.features.any((f) => f.contains('AI Stroke Analysis')), isTrue);
  });

  test('home tab indices match expected pro gates', () {
    expect(SubscriptionCapabilities.minimumTierForHomeTab(HomeTab.goals),
        SubscriptionTier.basic);
    expect(SubscriptionCapabilities.minimumTierForHomeTab(HomeTab.personalBests),
        SubscriptionTier.basic);
    expect(SubscriptionCapabilities.minimumTierForHomeTab(HomeTab.meetResults),
        SubscriptionTier.pro);
    expect(SubscriptionCapabilities.minimumTierForHomeTab(HomeTab.videoLab),
        SubscriptionTier.pro);
  });
}
