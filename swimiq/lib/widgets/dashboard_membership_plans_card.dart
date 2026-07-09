import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/subscription_plan.dart';
import '../core/services/stripe_checkout_support.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../screens/membership/membership_screen.dart';
import '../services/auth_service.dart';

/// Basic / Pro / Elite signup — shown on the dashboard right after sign-in.
class DashboardMembershipPlansCard extends ConsumerStatefulWidget {
  const DashboardMembershipPlansCard({super.key});

  @override
  ConsumerState<DashboardMembershipPlansCard> createState() =>
      _DashboardMembershipPlansCardState();
}

class _DashboardMembershipPlansCardState
    extends ConsumerState<DashboardMembershipPlansCard> {
  BillingCycle _billingCycle = BillingCycle.monthly;
  String? _message;

  Future<void> _selectPlan(SubscriptionTier tier) async {
    final subscription = ref.read(subscriptionStateProvider).value;
    final userEmail = ref.read(currentUserProvider)?.email;
    if (subscription == null) return;

    final blocked = SubscriptionCheckoutGuard.blockReason(
      subscription: subscription,
      userEmail: userEmail,
      tier: tier,
    );
    if (blocked != null) {
      setState(() => _message = blocked);
      return;
    }

    if (kIsWeb) {
      setState(() => _message = 'Opening secure Stripe checkout…');
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
        setState(() => _message = StripeCheckoutErrors.message(error));
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
          'Mobile billing uses Google Play / App Store at launch.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionStateProvider).value;
    final userEmail = ref.watch(currentUserProvider)?.email;
    if (subscription == null) return const SizedBox.shrink();

    final trialDays = subscription.isTrialActive && subscription.trialEndsAt != null
        ? subscription.trialEndsAt!.difference(DateTime.now()).inDays.clamp(0, 99)
        : null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Choose your SwimIQ plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeep,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MembershipScreen(),
                    ),
                  ),
                  child: const Text('Compare all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subscription.hasActiveServerPlan
                  ? 'You are on ${subscription.statusLabel}. Upgrade or change anytime.'
                  : trialDays != null
                      ? 'Elite trial active · $trialDays day${trialDays == 1 ? '' : 's'} left. '
                          'Lock in Basic, Pro, or Elite before it ends.'
                      : 'Every new athlete gets a ${SubscriptionCatalog.trialDays}-day Elite trial. '
                          'Pick the plan that fits your season.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<BillingCycle>(
              segments: const [
                ButtonSegment(value: BillingCycle.monthly, label: Text('Monthly')),
                ButtonSegment(value: BillingCycle.annual, label: Text('Annual')),
              ],
              selected: {_billingCycle},
              onSelectionChanged: (value) {
                setState(() => _billingCycle = value.first);
              },
            ),
            const SizedBox(height: 14),
            ...SubscriptionCatalog.plans.map(
              (plan) => _DashboardPlanTile(
                plan: plan,
                billingCycle: _billingCycle,
                buttonLabel: SubscriptionCheckoutGuard.buttonLabel(
                  subscription: subscription,
                  userEmail: userEmail,
                  tier: plan.tier,
                ),
                canCheckout: SubscriptionCheckoutGuard.canStartCheckout(
                  subscription: subscription,
                  userEmail: userEmail,
                  tier: plan.tier,
                ),
                onSelect: () => _selectPlan(plan.tier),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardPlanTile extends StatelessWidget {
  const _DashboardPlanTile({
    required this.plan,
    required this.billingCycle,
    required this.buttonLabel,
    required this.canCheckout,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final BillingCycle billingCycle;
  final String buttonLabel;
  final bool canCheckout;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final featured = plan.isFeatured;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: featured
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: featured
              ? AppColors.primary.withValues(alpha: 0.55)
              : Colors.grey.shade200,
          width: featured ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (plan.badgeLabel != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          plan.badgeLabel!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  plan.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.priceLabel(billingCycle),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                    fontSize: 18,
                  ),
                ),
                if (plan.savingsLabel(billingCycle) != null)
                  Text(
                    plan.savingsLabel(billingCycle)!,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canCheckout ? onSelect : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
