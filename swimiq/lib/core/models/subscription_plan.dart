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
    this.isFeatured = false,
    this.badgeLabel,
  });

  final SubscriptionTier tier;
  final String name;
  final String tagline;
  final double monthlyPriceUsd;
  final double annualPriceUsd;
  final List<String> features;
  final bool isFeatured;
  final String? badgeLabel;

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
  static const coachTrialDays = 14;
  static const coachElitePeekDays = 7;
  static const coachEliteAnalysisLimit = 5;
  static const coachAccessCode = 'COACH-EVAL-14';
  static const legacyCoachAccessCode = 'COACH-TRIAL-30';

  static bool isCoachAccessCode(String code) {
    final normalized = code.trim().toUpperCase();
    return normalized == coachAccessCode ||
        normalized == legacyCoachAccessCode;
  }

  static const plans = [
    SubscriptionPlan(
      tier: SubscriptionTier.basic,
      name: 'SwimIQ Basic',
      tagline: 'Logs & simple training tracking',
      monthlyPriceUsd: 4.99,
      annualPriceUsd: 39.99,
      isFeatured: false,
      features: [
        'Training log & add session',
        'Simple dashboard overview',
        'Session history',
        'Perfect for casual swimmers & parents',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.pro,
      name: 'SwimIQ Pro',
      tagline: 'Analytics, goals & race tracking',
      monthlyPriceUsd: 9.99,
      annualPriceUsd: 89.99,
      isFeatured: true,
      badgeLabel: 'Most Popular',
      features: [
        'Everything in Basic',
        'Personal bests & meet results',
        'Goals with progress tracking',
        'Athlete Passport & recruiting snapshot',
        'USA motivational cuts & standards',
        'Video library (upload & review)',
        'Daily rope climb & badges',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.elite,
      name: 'SwimIQ Elite',
      tagline: 'Advanced AI performance coaching',
      monthlyPriceUsd: 19.99,
      annualPriceUsd: 149.99,
      isFeatured: false,
      badgeLabel: 'Advanced AI Performance',
      features: [
        'Everything in Pro',
        'SwimIQ AI video analysis',
        'Race Intelligence meet-day plans',
        'AI nutrition & warmup guidance',
        'Priority performance insights',
        'Built for high-performance families & coaches',
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
