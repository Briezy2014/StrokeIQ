import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/founder_account_constants.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/legal_footer.dart';
import '../../widgets/subscription_feature_matrix.dart';
import '../../widgets/swimiq_header.dart';
import '../../widgets/swimiq_logo.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  BillingCycle _billingCycle = BillingCycle.monthly;
  final _coachCodeController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _coachCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectPlan(SubscriptionTier tier) async {
    if (kIsWeb) {
      setState(() {
        _message = 'Opening secure Stripe checkout…';
      });
      try {
        final url = await ref
            .read(subscriptionStateProvider.notifier)
            .startStripeCheckout(tier, _billingCycle);
        if (!mounted) return;
        final opened = await launchUrl(
          Uri.parse(url),
          webOnlyWindowName: '_self',
        );
        if (!mounted) return;
        setState(() {
          _message = opened
              ? 'Complete payment in Stripe, then return to SwimIQ.'
              : 'Could not open checkout. Allow pop-ups and try again.';
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _message = 'Checkout error: $error';
        });
      }
      return;
    }

    await ref
        .read(subscriptionStateProvider.notifier)
        .selectPlan(tier, _billingCycle);
    if (!mounted) return;
    setState(() {
      _message =
          'Selected ${SubscriptionCatalog.planFor(tier).name} (${_billingCycle.name}). '
          'Mobile app billing uses Google Play / App Store at launch.';
    });
  }

  Future<void> _redeemCoachCode() async {
    final error = await ref
        .read(subscriptionStateProvider.notifier)
        .redeemCoachCode(_coachCodeController.text);
    if (!mounted) return;
    setState(() {
      _message = error ??
          'Coach preview unlocked: ${SubscriptionCatalog.coachTrialDays}-day Pro access plus '
          '${SubscriptionCatalog.coachElitePeekDays}-day Elite AI sneak peek '
          '(${SubscriptionCatalog.coachEliteAnalysisLimit} video analyses).';
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionStateProvider);
    final user = ref.watch(currentUserProvider);
    final showCoachAdmin = FounderAccountConstants.canViewCoachAdminCodes(user?.email);

    return Scaffold(
      appBar: AppBar(
        title: const SwimIqScreenAppBarTitle('Membership'),
      ),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load plans: $error')),
        data: (subscription) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryDeep,
                      AppColors.primary,
                      AppColors.accent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.statusLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        SwimIqCompactMark(size: 52, borderRadius: 14),
                        SizedBox(width: 14),
                        Expanded(
                          child: SwimIqWordmark(fontSize: 26),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Every new athlete gets a ${SubscriptionCatalog.trialDays}-day Elite trial. '
                      'Choose monthly or annual billing when you are ready.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.4,
                      ),
                    ),
                    if (subscription.isCoachTrialActive) ...[
                      const SizedBox(height: 10),
                      Text(
                        SubscriptionCapabilities.coachPreviewSummary(subscription),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SegmentedButton<BillingCycle>(
                segments: const [
                  ButtonSegment(
                    value: BillingCycle.monthly,
                    label: Text('Monthly'),
                  ),
                  ButtonSegment(
                    value: BillingCycle.annual,
                    label: Text('Annual'),
                  ),
                ],
                selected: {_billingCycle},
                onSelectionChanged: (value) {
                  setState(() => _billingCycle = value.first);
                },
              ),
              const SizedBox(height: 20),
              const SubscriptionFeatureMatrix(),
              const SizedBox(height: 20),
              ...SubscriptionCatalog.plans.map(
                (plan) => _PlanCard(
                  plan: plan,
                  billingCycle: _billingCycle,
                  isCurrent: subscription.effectiveTier == plan.tier,
                  onSelect: () => _selectPlan(plan.tier),
                ),
              ),
              if (showCoachAdmin) ...[
                const SizedBox(height: 24),
                Text(
                  'Coach preview access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coaches evaluate SwimIQ before buying for their team:\n'
                  '• ${SubscriptionCatalog.coachTrialDays}-day Pro access (full analytics & passport)\n'
                  '• ${SubscriptionCatalog.coachElitePeekDays}-day Elite AI sneak peek\n'
                  '• ${SubscriptionCatalog.coachEliteAnalysisLimit} SwimIQ AI video analyses during preview\n\n'
                  'Codes: ${SubscriptionCatalog.coachAccessCode} or ${SubscriptionCatalog.legacyCoachAccessCode}',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _coachCodeController,
                  decoration: InputDecoration(
                    labelText: 'Coach access code',
                    hintText: SubscriptionCatalog.coachAccessCode,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _redeemCoachCode,
                  child: const Text('Unlock coach preview'),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const LegalFooter(),
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.isCurrent,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final BillingCycle billingCycle;
  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: plan.isFeatured ? AppColors.primary : Colors.grey.shade200,
          width: plan.isFeatured ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (plan.badgeLabel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: plan.isFeatured
                          ? AppColors.primary
                          : AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      plan.badgeLabel!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ] else if (plan.isFeatured) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(plan.tagline),
            const SizedBox(height: 12),
            Text(
              plan.priceLabel(billingCycle),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            if (plan.savingsLabel(billingCycle) != null) ...[
              const SizedBox(height: 4),
              Text(
                plan.savingsLabel(billingCycle)!,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onSelect,
              child: Text(isCurrent ? 'Current plan' : 'Choose ${plan.name}'),
            ),
          ],
        ),
      ),
    );
  }
}
