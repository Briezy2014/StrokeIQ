import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/models/subscription_plan.dart';
import 'package:swimiq/core/services/stripe_checkout_support.dart';
import 'package:swimiq/core/services/subscription_service.dart';

void main() {
  test('checkout URLs use localhost origin on web tests', () {
    expect(StripeCheckoutUrls.successUrl(), contains('checkout=success'));
    expect(StripeCheckoutUrls.cancelUrl(), contains('checkout=cancel'));
  });

  test('failed fetch maps to deploy guidance', () {
    final message = StripeCheckoutErrors.message(
      Exception('ClientException: Failed to fetch'),
    );
    expect(message, contains('STRIPE_SETUP'));
    expect(message, contains('create-stripe-checkout'));
  });

  test('founder accounts cannot start checkout', () {
    const subscription = SubscriptionState(
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

    expect(
      SubscriptionCheckoutGuard.canStartCheckout(
        subscription: subscription,
        userEmail: 'briezy682014@gmail.com',
        tier: SubscriptionTier.pro,
      ),
      isFalse,
    );
    expect(
      SubscriptionCheckoutGuard.buttonLabel(
        subscription: subscription,
        userEmail: 'briezy682014@gmail.com',
        tier: SubscriptionTier.elite,
      ),
      'Included',
    );
  });

  test('elite trial blocks elite checkout but allows pro', () {
    final subscription = SubscriptionState(
      tier: SubscriptionTier.trial,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: DateTime.now().add(const Duration(days: 2)),
      coachTrialEndsAt: null,
      coachTrialStartedAt: null,
      coachAiAnalysesUsed: 0,
      hasUsedTrial: true,
    );

    expect(
      SubscriptionCheckoutGuard.canStartCheckout(
        subscription: subscription,
        userEmail: 'athlete@example.com',
        tier: SubscriptionTier.elite,
      ),
      isFalse,
    );
    expect(
      SubscriptionCheckoutGuard.canStartCheckout(
        subscription: subscription,
        userEmail: 'athlete@example.com',
        tier: SubscriptionTier.pro,
      ),
      isTrue,
    );
    expect(
      SubscriptionCheckoutGuard.buttonLabel(
        subscription: subscription,
        userEmail: 'athlete@example.com',
        tier: SubscriptionTier.elite,
      ),
      'Trial',
    );
  });
}
