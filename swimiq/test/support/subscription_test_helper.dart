import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimiq/core/models/subscription_plan.dart';
import 'package:swimiq/core/services/subscription_service.dart';
import 'package:swimiq/providers/app_providers.dart';

class TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionState> build() async {
    return SubscriptionState(
      tier: SubscriptionTier.elite,
      billingCycle: BillingCycle.monthly,
      trialEndsAt: DateTime.now().add(const Duration(days: 3)),
      coachTrialEndsAt: null,
      hasUsedTrial: true,
    );
  }
}

List<Override> get subscriptionTestOverrides => [
      subscriptionStateProvider.overrideWith(TestSubscriptionNotifier.new),
    ];
