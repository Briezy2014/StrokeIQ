import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/models/subscription_plan.dart';
import 'package:swimiq/core/services/subscription_service.dart';
import 'package:swimiq/core/subscription/subscription_capabilities.dart';

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
}
