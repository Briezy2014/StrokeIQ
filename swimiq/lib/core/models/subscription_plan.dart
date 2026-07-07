enum BillingCycle { monthly, annual }

enum SubscriptionTier { trial, basic, pro, elite, coach }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.monthlyPriceUsd,
    required this.annualPriceUsd,
    required this.features,
    required this.isFeatured,
  });

  final SubscriptionTier tier;
  final String name;
  final String tagline;
  final double monthlyPriceUsd;
  final double annualPriceUsd;
  final List<String> features;
  final bool isFeatured;

  double priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.monthly ? monthlyPriceUsd : annualPriceUsd;

  String priceLabel(BillingCycle cycle) {
    if (tier == SubscriptionTier.trial) return '3-day Elite trial';
    if (tier == SubscriptionTier.coach) return 'Coach preview access';
    final price = priceFor(cycle);
    return cycle == BillingCycle.monthly
        ? '\$${price.toStringAsFixed(2)}/mo'
        : '\$${price.toStringAsFixed(0)}/yr';
  }

  String? savingsLabel(BillingCycle cycle) {
    if (tier == SubscriptionTier.trial || tier == SubscriptionTier.coach) {
      return null;
    }
    if (cycle != BillingCycle.annual) return null;
    final monthlyTotal = monthlyPriceUsd * 12;
    final savings = monthlyTotal - annualPriceUsd;
    if (savings <= 0) return null;
    final percent = ((savings / monthlyTotal) * 100).round();
    return 'Save $percent% vs monthly';
  }
}

abstract final class SubscriptionCatalog {
  static const trialDays = 3;
  static const coachTrialDays = 30;
  static const coachAccessCode = 'COACH-TRIAL-30';

  static const plans = [
    SubscriptionPlan(
      tier: SubscriptionTier.basic,
      name: 'Basic',
      tagline: 'Train smarter every day',
      monthlyPriceUsd: 4.99,
      annualPriceUsd: 39.99,
      isFeatured: false,
      features: [
        'SwimIQ Dashboard',
        'Training log',
        'Goals tracking',
        'Session history',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.pro,
      name: 'Pro',
      tagline: 'Competition-ready analytics',
      monthlyPriceUsd: 9.99,
      annualPriceUsd: 89.99,
      isFeatured: false,
      features: [
        'Everything in Basic',
        'Personal bests + meet results',
        'Motivational cuts & USA standards',
        'Athlete Passport',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.elite,
      name: 'Elite',
      tagline: 'The full SwimIQ performance stack',
      monthlyPriceUsd: 19.99,
      annualPriceUsd: 149.99,
      isFeatured: true,
      features: [
        'Everything in Pro',
        'Video Lab + SwimIQ AI coach',
        'Pose metrics & race intelligence',
        'Priority dashboard insights',
        'Recruiting center (coming soon)',
      ],
    ),
  ];

  static SubscriptionPlan planFor(SubscriptionTier tier) {
    return plans.firstWhere(
      (plan) => plan.tier == tier,
      orElse: () => plans.first,
    );
  }
}
