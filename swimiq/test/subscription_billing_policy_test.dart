import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/models/subscription_plan.dart';
import 'package:swimiq/core/subscription/subscription_billing_policy.dart';

void main() {
  group('SubscriptionBillingPolicy', () {
    test('unit tests run with kIsWeb false so mobile checkout is blocked', () {
      expect(SubscriptionBillingPolicy.supportsStripeCheckout, isFalse);
      expect(SubscriptionBillingPolicy.supportsPaidPlanSelection, isFalse);
    });

    test('android blocks paid plan selection with Play messaging', () {
      final elite = SubscriptionCatalog.planFor(SubscriptionTier.elite);
      expect(
        SubscriptionBillingPolicy.paidPlanButtonLabel(
          plan: elite,
          isCurrent: false,
          platform: TargetPlatform.android,
        ),
        'Google Play billing soon',
      );
      expect(
        SubscriptionBillingPolicy.mobilePaidPlansHeadline(
          TargetPlatform.android,
        ),
        contains('Google Play billing'),
      );
      expect(
        SubscriptionBillingPolicy.paidPlanSelectionBlockedMessage(
          TargetPlatform.android,
        ),
        contains('Google Play billing'),
      );
    });

    test('iOS blocks paid plan selection with App Store messaging', () {
      final pro = SubscriptionCatalog.planFor(SubscriptionTier.pro);
      expect(
        SubscriptionBillingPolicy.paidPlanButtonLabel(
          plan: pro,
          isCurrent: false,
          platform: TargetPlatform.iOS,
        ),
        'App Store billing soon',
      );
      expect(
        SubscriptionBillingPolicy.mobilePaidPlansHeadline(TargetPlatform.iOS),
        contains('App Store billing'),
      );
    });

    test('web checkout uses choose-plan labels when paid selection is enabled',
        () {
      final elite = SubscriptionCatalog.planFor(SubscriptionTier.elite);
      expect(
        SubscriptionBillingPolicy.paidPlanButtonLabel(
          plan: elite,
          isCurrent: false,
          platform: TargetPlatform.linux,
        ),
        'Google Play billing soon',
      );
    });

    test('current plan label is unchanged on mobile', () {
      final elite = SubscriptionCatalog.planFor(SubscriptionTier.elite);
      expect(
        SubscriptionBillingPolicy.paidPlanButtonLabel(
          plan: elite,
          isCurrent: true,
          platform: TargetPlatform.android,
        ),
        'Current plan',
      );
    });
  });
}
