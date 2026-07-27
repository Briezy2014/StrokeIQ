import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/subscription/ambassador_catalog.dart';
import '../../core/subscription/subscription_billing_policy.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/legal_footer.dart';

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
    if (SubscriptionBillingPolicy.supportsStripeCheckout) {
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

    final blocked = SubscriptionBillingPolicy.paidPlanSelectionBlockedMessage(
      defaultTargetPlatform,
    );
    if (!mounted) return;
    setState(() {
      _message = blocked;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('SwimIQ Membership'),
      ),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load plans: $error')),
        data: (subscription) {
          final paidPlansAvailable =
              SubscriptionBillingPolicy.supportsPaidPlanSelection;
          final billingHeadline = paidPlansAvailable
              ? 'Every new athlete gets a ${SubscriptionCatalog.trialDays}-day Elite trial. '
                  'Choose monthly or annual billing when you are ready.'
              : SubscriptionBillingPolicy.mobilePaidPlansHeadline(
                  defaultTargetPlatform,
                );
          final billingDetail = paidPlansAvailable
              ? null
              : SubscriptionBillingPolicy.mobilePaidPlansDetail(
                  defaultTargetPlatform,
                );

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
                    const SizedBox(height: 8),
                    const Text(
                      'Built in the Water.\nDriven by Possibility.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      billingHeadline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.4,
                      ),
                    ),
                    if (billingDetail != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        billingDetail,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
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
              if (paidPlansAvailable)
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
              if (paidPlansAvailable) const SizedBox(height: 20),
              ...SubscriptionCatalog.plans.map(
                (plan) => _PlanCard(
                  plan: plan,
                  billingCycle: _billingCycle,
                  isCurrent: subscription.effectiveTier == plan.tier,
                  paidPlansAvailable: paidPlansAvailable,
                  onSelect: paidPlansAvailable
                      ? () => _selectPlan(plan.tier)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Coach / ambassador preview access',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coaches and ambassadors evaluate SwimIQ before buying:\n'
                '• ${SubscriptionCatalog.coachTrialDays}-day Pro access (full analytics & passport)\n'
                '• ${SubscriptionCatalog.coachElitePeekDays}-day Elite AI sneak peek\n'
                '• ${SubscriptionCatalog.coachEliteAnalysisLimit} SwimIQ AI video analyses during preview\n\n'
                'Coach codes: ${SubscriptionCatalog.coachAccessCode} or ${SubscriptionCatalog.legacyCoachAccessCode}\n'
                'Ambassador codes: ${AmbassadorCatalog.ruslan.code}, ${AmbassadorCatalog.nyah.code}, or ${SubscriptionCatalog.ambassadorAccessCode}',
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _coachCodeController,
                decoration: InputDecoration(
                  labelText: 'Coach or ambassador code',
                  hintText: SubscriptionCatalog.ambassadorAccessCode,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _redeemCoachCode,
                child: const Text('Unlock preview'),
              ),
              const SizedBox(height: 20),
              Text(
                'Named ambassador links (for 30% attribution)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Each ambassador gets a unique link. Use these when sending to Ruslan, Nyah, or future ambassadors. '
                'Connect Rewardful to Stripe so paid checkouts credit the right person.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final ambassador in AmbassadorCatalog.named) ...[
                _AmbassadorShareCard(
                  ambassador: ambassador,
                  onCopied: (label) {
                    setState(() => _message = '$label copied.');
                  },
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Shared ambassador link (preview only — not for commissions)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send this only when you do not need to track who referred the signup:',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 8),
              SelectableText(
                SubscriptionCatalog.ambassadorShareUrl,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(
                          text: SubscriptionCatalog.ambassadorShareUrl,
                        ),
                      );
                      if (!mounted) return;
                      setState(() {
                        _message = 'Shared ambassador link copied.';
                      });
                    },
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Copy shared link'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(
                          text: SubscriptionCatalog.ambassadorAccessCode,
                        ),
                      );
                      if (!mounted) return;
                      setState(() {
                        _message = 'Shared ambassador code copied.';
                      });
                    },
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Copy shared code'),
                  ),
                ],
              ),
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

class _AmbassadorShareCard extends StatelessWidget {
  const _AmbassadorShareCard({
    required this.ambassador,
    required this.onCopied,
  });

  final SwimIqAmbassador ambassador;
  final void Function(String label) onCopied;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ambassador.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text('Code: ${ambassador.code}'),
          const SizedBox(height: 4),
          SelectableText(
            ambassador.preferredShareUrl,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: ambassador.preferredShareUrl),
                  );
                  onCopied('${ambassador.name} link');
                },
                icon: const Icon(Icons.link, size: 18),
                label: Text('Copy ${ambassador.name} link'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: ambassador.code),
                  );
                  onCopied('${ambassador.name} code');
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copy code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.isCurrent,
    required this.paidPlansAvailable,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final BillingCycle billingCycle;
  final bool isCurrent;
  final bool paidPlansAvailable;
  final VoidCallback? onSelect;

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
                if (plan.isFeatured) ...[
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
              onPressed: paidPlansAvailable ? onSelect : null,
              child: Text(
                SubscriptionBillingPolicy.paidPlanButtonLabel(
                  plan: plan,
                  isCurrent: isCurrent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
