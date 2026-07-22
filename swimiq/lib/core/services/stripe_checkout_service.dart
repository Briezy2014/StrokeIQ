import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription_plan.dart';

/// Starts a Stripe Checkout session via Supabase Edge Function.
class StripeCheckoutService {
  StripeCheckoutService(this._client);

  final SupabaseClient _client;

  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingCycle billingCycle,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final response = await _client.functions.invoke(
      'create-stripe-checkout',
      body: {
        'tier': tier.name,
        'billing_cycle': billingCycle.name,
        if (successUrl != null) 'success_url': successUrl,
        if (cancelUrl != null) 'cancel_url': cancelUrl,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      throw Exception(
        'Checkout failed (${response.status}). Please try again shortly.',
      );
    }

    final data = response.data;
    if (data is! Map || data['url'] == null) {
      throw Exception('Checkout did not return a payment URL.');
    }
    return data['url'] as String;
  }
}
