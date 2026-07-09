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
      tagline: 'Track your progress, crush your goals, and build momentum every week',
      monthlyPriceUsd: 4.99,
      annualPriceUsd: 39.99,
      isFeatured: false,
      features: [
        'Dashboard — rope climb, cuts progress & your weekly snapshot',
        'Training log — log swims, practices & upload meet/practice photos',
        'Goals with visual progress charts from your real times',
        'Weekly Progress Report — see how you\'re trending',
        'In-app personal bests & full time history',
        'Progress charts, streaks, badges & milestone celebrations',
        'Perfect for new club swimmers, recreational athletes & anyone building consistency',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.pro,
      name: 'SwimIQ Pro',
      tagline: 'The competitive edge — official times, recruiting tools & train smarter outside the pool',
      monthlyPriceUsd: 9.99,
      annualPriceUsd: 89.99,
      isFeatured: true,
      badgeLabel: 'Most Popular',
      features: [
        'Everything in Basic',
        'Official PBs, meet results & USA Swimming motivational cuts',
        'Athlete Passport & College Recruiting Hub — your digital swim résumé',
        'Best Times Résumé, Meet History & recruiting snapshot exports',
        'Video Lab — upload, tag & organize race & technique videos',
        'AI Dryland Coach — strength, core, mobility & injury prevention (5–15 min sessions)',
        'Event-specific improvement tips tied to your actual times',
        'Goal progression analytics powered by meet results & training logs',
        'Built for USA Swimming athletes chasing cuts, PRs & college interest',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.elite,
      name: 'SwimIQ Elite',
      tagline: 'Your AI performance coach — video analysis, race intelligence & recruiting insights',
      monthlyPriceUsd: 19.99,
      annualPriceUsd: 149.99,
      isFeatured: false,
      badgeLabel: 'Advanced AI Performance',
      features: [
        'Everything in Pro',
        'AI Video Stroke Analysis (Gemini + MediaPipe) — mechanics, kick, catch, turns & underwater',
        'Pros/cons coach summary with youth-friendly notes & estimated time savings',
        'Race Intelligence — pacing, split analysis, tempo shifts & fatigue detection',
        'AI Performance Reports with your top improvement priorities',
        'Personalized race strategy recommendations for your events',
        'Season performance insights across meets & training blocks',
        'AI Recruiting Intelligence — college program match, projections & talking points',
        'Unlimited SwimIQ AI video analyses in Video Lab',
        'For serious competitors who want data-driven coaching between pool sessions',
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
