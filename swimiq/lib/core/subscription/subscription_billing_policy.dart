import 'package:flutter/foundation.dart';

import '../models/subscription_plan.dart';

/// Where paid checkout is allowed (Play/App Store billing comes in a later release).
abstract final class SubscriptionBillingPolicy {
  static bool get supportsStripeCheckout => kIsWeb;

  static bool get supportsPaidPlanSelection => kIsWeb;

  static String mobilePaidPlansHeadline(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android =>
        'Paid plans arrive with Google Play billing in an upcoming update.',
      TargetPlatform.iOS =>
        'Paid plans arrive with App Store billing in an upcoming update.',
      _ => 'Paid plans are available on swimiqapp.com today.',
    };
  }

  static String mobilePaidPlansDetail(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android =>
        'Your ${SubscriptionCatalog.trialDays}-day Elite trial and coach preview codes '
        'work in the app now. Subscribe on Android when Google Play billing ships.',
      TargetPlatform.iOS =>
        'Your ${SubscriptionCatalog.trialDays}-day Elite trial and coach preview codes '
        'work in the app now. Subscribe on iPhone when App Store billing ships.',
      _ =>
        'Open swimiqapp.com in a browser to subscribe with Stripe while mobile '
        'store billing is in development.',
    };
  }

  static String paidPlanButtonLabel({
    required SubscriptionPlan plan,
    required bool isCurrent,
    TargetPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    if (isCurrent) return 'Current plan';
    if (supportsPaidPlanSelection) return 'Choose ${plan.name}';
    return switch (resolvedPlatform) {
      TargetPlatform.android => 'Google Play billing soon',
      TargetPlatform.iOS => 'App Store billing soon',
      _ => 'Subscribe on swimiqapp.com',
    };
  }

  static String? paidPlanSelectionBlockedMessage(TargetPlatform platform) {
    if (supportsPaidPlanSelection) return null;
    return switch (platform) {
      TargetPlatform.android =>
        'In-app subscriptions on Android launch with Google Play billing soon. '
        'Use your Elite trial or a coach preview code until then.',
      TargetPlatform.iOS =>
        'In-app subscriptions on iPhone launch with App Store billing soon. '
        'Use your Elite trial or a coach preview code until then.',
      _ => null,
    };
  }
}
