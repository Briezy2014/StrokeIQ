import 'package:flutter_test/flutter_test.dart';
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

    expect(SubscriptionCapabilities.canAccessHomeTab(0, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(1, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(2, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(3, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(4, state), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(5, state), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(6, state), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(7, state), isFalse);
    expect(SubscriptionCapabilities.canAccessGoals(state), isTrue);
    expect(SubscriptionCapabilities.canAccessBasicPersonalBests(state), isTrue);
    expect(SubscriptionCapabilities.canAccessWeeklyProgressReport(state), isTrue);
    expect(SubscriptionCapabilities.canAccessDashboardGamification(state), isTrue);
    expect(SubscriptionCapabilities.canAccessOfficialPbsAndStandards(state), isFalse);
    expect(SubscriptionCapabilities.canAccessAiDrylandCoach(state), isFalse);
    expect(SubscriptionCapabilities.canRunSwimIqAiAnalysis(state), isFalse);
  });

  test('subscription loading locks pro tabs until loaded', () {
    expect(SubscriptionCapabilities.canAccessHomeTab(0, null), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(4, null), isTrue);
    expect(SubscriptionCapabilities.canAccessHomeTab(5, null), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(6, null), isFalse);
    expect(SubscriptionCapabilities.canAccessHomeTab(7, null), isFalse);
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
