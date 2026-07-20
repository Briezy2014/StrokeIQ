import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/subscription_service.dart';
import '../core/subscription/subscription_capabilities.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../screens/membership/membership_screen.dart';
import '../services/auth_service.dart';
import 'personal_best_upload_sheet.dart';

class PersonalBestsActionBar extends ConsumerWidget {
  const PersonalBestsActionBar({
    super.key,
    required this.showOfficial,
  });

  final bool showOfficial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Center(
          child: FilledButton.icon(
            onPressed: () => _onUploadPressed(context, ref),
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Upload best times'),
          ),
        ),
      ),
    );
  }

  Future<void> _onUploadPressed(BuildContext context, WidgetRef ref) async {
    final email = ref.read(currentUserProvider)?.email;
    final subscription = ref.read(subscriptionStateProvider).value;

    // Master/founder/demo always upload — never dump to Membership.
    final builtInElite = SubscriptionService.isBuiltInEliteEmail(email);
    if (builtInElite &&
        (subscription == null || !subscription.isDemoMaster)) {
      await ref.read(subscriptionStateProvider.notifier).refreshFromServer();
    }

    final allowed = showOfficial ||
        builtInElite ||
        (subscription != null &&
            SubscriptionCapabilities.canAccessOfficialPbsAndStandards(
              subscription,
            ));

    if (allowed) {
      if (!context.mounted) return;
      await showPersonalBestUploadChooser(context);
      return;
    }

    if (!context.mounted) return;
    final goUpgrade = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Official best times'),
        content: Text(
          'Uploading official best times (photo / file) is included with '
          'SwimIQ Pro.\n\n'
          'Signed in as: ${email ?? 'unknown'}\n'
          'Master Elite login: briezy682014@gmail.com',
          style: TextStyle(
            color: AppColors.textDark.withValues(alpha: 0.9),
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('View plans'),
          ),
        ],
      ),
    );
    if (goUpgrade == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MembershipScreen(),
        ),
      );
    }
  }
}
