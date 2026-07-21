import '../constants/founder_account_constants.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';
import 'package:flutter/foundation.dart';

/// Stripe Checkout return URLs — use current origin on localhost, production on live site.
abstract final class StripeCheckoutUrls {
  static const productionOrigin = 'https://swimiqapp.com';

  static String checkoutOrigin() {
    if (kIsWeb) {
      final origin = Uri.base.origin.trim();
      if (origin.isNotEmpty &&
          origin != 'null' &&
          !origin.contains('about:')) {
        return origin;
      }
    }
    return productionOrigin;
  }

  static String successUrl() => '${checkoutOrigin()}/?checkout=success';

  static String cancelUrl() => '${checkoutOrigin()}/?checkout=cancel';
}

/// User-friendly messages for Stripe / Supabase checkout failures.
abstract final class StripeCheckoutErrors {
  static String message(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('failed to fetch') ||
        text.contains('connection') ||
        text.contains('socketexception') ||
        text.contains('network')) {
      return 'Billing is temporarily unavailable. '
          'Please try again in a few minutes, or email support@swimiqapp.com.';
    }
    if (text.contains('stripe_secret_key') ||
        text.contains('not configured') ||
        text.contains('missing stripe price') ||
        text.contains('create-stripe-checkout') ||
        text.contains('edge function')) {
      return 'Checkout is not ready yet. '
          'Please try again shortly, or email support@swimiqapp.com.';
    }
    if (text.contains('unauthorized') || text.contains('401')) {
      return 'Please sign in again, then try checkout.';
    }
    if (text.contains('invalid tier') || text.contains('billing_cycle')) {
      return 'Could not start checkout for that plan. Try again or contact support.';
    }

    return 'Could not start checkout. Please try again, '
        'or email support@swimiqapp.com if it keeps failing.';
  }
}

abstract final class SubscriptionCheckoutGuard {
  static String? blockReason({
    required SubscriptionState subscription,
    required String? userEmail,
    required SubscriptionTier tier,
  }) {
    if (FounderAccountConstants.isFounderEmail(userEmail) ||
        subscription.isDemoMaster) {
      return 'Your account already has full Elite access for testing — '
          'no purchase needed.';
    }
    if (subscription.hasActiveServerPlan && subscription.effectiveTier == tier) {
      return 'You already have an active ${SubscriptionCatalog.planFor(tier).name} subscription.';
    }
    if (subscription.isTrialActive && tier == SubscriptionTier.elite) {
      return 'You are on the free Elite trial. Choose Basic or Pro to subscribe now, '
          'or subscribe to Elite when your trial ends.';
    }
    return null;
  }

  static String buttonLabel({
    required SubscriptionState subscription,
    required String? userEmail,
    required SubscriptionTier tier,
  }) {
    if (FounderAccountConstants.isFounderEmail(userEmail) ||
        subscription.isDemoMaster) {
      return 'Included';
    }
    if (subscription.hasActiveServerPlan && subscription.effectiveTier == tier) {
      return 'Current';
    }
    if (subscription.isTrialActive && tier == SubscriptionTier.elite) {
      return 'Trial';
    }
    return 'Choose';
  }

  static bool canStartCheckout({
    required SubscriptionState subscription,
    required String? userEmail,
    required SubscriptionTier tier,
  }) {
    return blockReason(
          subscription: subscription,
          userEmail: userEmail,
          tier: tier,
        ) ==
        null;
  }
}
