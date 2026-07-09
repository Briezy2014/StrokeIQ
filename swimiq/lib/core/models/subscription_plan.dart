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
      name: 'Basic',
      tagline: 'Every swim counts — build your momentum',
      monthlyPriceUsd: 4.99,
      annualPriceUsd: 39.99,
      isFeatured: false,
      features: [
        'SwimIQ Dashboard — your week at a glance',
        'Training log — capture every practice & set',
        'Goals with progress you can actually feel',
        'Full session history & activity trends',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.pro,
      name: 'Pro',
      tagline: 'Turn your data into drop-the-hammer moments',
      monthlyPriceUsd: 9.99,
      annualPriceUsd: 89.99,
      isFeatured: false,
      features: [
        'Everything in Basic — fully unlocked',
        'Personal bests & meet results — your PR wall, auto-updated',
        'USA Motivational cuts — know exactly which cut you\'re chasing',
        'Athlete Passport™ Command Center — profile, stats & recruiting snapshot',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.elite,
      name: 'Elite',
      tagline: 'The wild factor — AI, video & race-day dominance',
      monthlyPriceUsd: 19.99,
      annualPriceUsd: 149.99,
      isFeatured: true,
      features: [
        'Everything in Pro',
        'Video Lab — your personal film room for race footage',
        'SwimIQ AI Coach — unlimited video analysis & stroke feedback',
        'SwimDNA™ pose metrics — technique insights from your videos',
        'Race Intelligence™ — meet-day nutrition, warm-up & checklist',
        'Recruiting Center — college-track athlete snapshot',
        'Passport AI Coach — smart next-step recommendations',
        'Priority dashboard insights tuned to your season',
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
