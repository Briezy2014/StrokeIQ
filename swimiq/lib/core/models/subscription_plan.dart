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
      tagline: 'Everything you need to build a strong swimming foundation',
      monthlyPriceUsd: 4.99,
      annualPriceUsd: 39.99,
      isFeatured: false,
      features: [
        'Dashboard with performance overview',
        'Training log — swims, practices & photo upload',
        'Goal setting & goal tracking',
        'Weekly Progress Report',
        'In-app personal best tracking',
        'Progress charts & training history',
        'Swim streaks & milestone achievements',
        'Perfect for recreational swimmers & new USA Swimming athletes',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.pro,
      name: 'SwimIQ Pro',
      tagline: 'Powerful tools to improve outside the pool',
      monthlyPriceUsd: 9.99,
      annualPriceUsd: 89.99,
      isFeatured: true,
      badgeLabel: 'Most Popular',
      features: [
        'Everything in Basic',
        'Official PBs, meet results & USA Swimming standards',
        'Athlete Passport & College Recruiting Hub',
        'Best Times Résumé & Meet History',
        'Video Lab (upload & organize videos)',
        'AI Dryland Coach — strength, core, mobility, injury prevention & stability',
        'Event-specific improvement recommendations',
        'Goal progression tracking',
        'Perfect for competitive swimmers complementing their coach\'s plan',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.elite,
      name: 'SwimIQ Elite',
      tagline: 'Advanced AI performance intelligence',
      monthlyPriceUsd: 19.99,
      annualPriceUsd: 149.99,
      isFeatured: false,
      badgeLabel: 'Advanced AI Performance',
      features: [
        'Everything in Pro',
        'AI Stroke Analysis — mechanics, kick, catch, turns & more',
        'Race Intelligence — pacing, splits, tempo & fatigue detection',
        'AI Performance Reports & improvement priorities',
        'AI-generated race strategy recommendations',
        'AI-powered season performance insights',
        'AI Recruiting Intelligence — college match & projections',
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
