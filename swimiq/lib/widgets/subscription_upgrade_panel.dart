import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/models/subscription_plan.dart';
import '../core/subscription/subscription_capabilities.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../screens/membership/membership_screen.dart';

/// Full-screen upgrade prompt when a tier is required.
class SubscriptionUpgradePanel extends ConsumerWidget {
  const SubscriptionUpgradePanel({
    super.key,
    required this.minimumTier,
    required this.title,
    required this.message,
    this.teaserFeatures = const [],
  });

  final SubscriptionTier minimumTier;
  final String title;
  final String message;
  final List<String> teaserFeatures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = SubscriptionCatalog.planFor(
      minimumTier == SubscriptionTier.elite
          ? SubscriptionTier.elite
          : SubscriptionTier.pro,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          minimumTier == SubscriptionTier.elite
              ? Icons.auto_awesome
              : Icons.workspace_premium_outlined,
          size: 56,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        if (teaserFeatures.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...teaserFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MembershipScreen(),
              ),
            );
          },
          child: Text('Upgrade to ${plan.name}'),
        ),
      ],
    );
  }
}

/// Wraps a screen; shows [child] when tier met, else upgrade panel.
class SubscriptionGatedScreen extends ConsumerWidget {
  const SubscriptionGatedScreen({
    super.key,
    required this.minimumTier,
    required this.title,
    required this.message,
    required this.child,
    this.teaserFeatures = const [],
  });

  final SubscriptionTier minimumTier;
  final String title;
  final String message;
  final Widget child;
  final List<String> teaserFeatures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConstants.unlockAllTabsForPreview) return child;

    final subscription = ref.watch(subscriptionStateProvider).value;
    if (subscription == null ||
        !SubscriptionCapabilities.meetsMinimumTier(
          subscription,
          minimumTier,
        )) {
      return SubscriptionUpgradePanel(
        minimumTier: minimumTier,
        title: title,
        message: message,
        teaserFeatures: teaserFeatures,
      );
    }
    return child;
  }
}
