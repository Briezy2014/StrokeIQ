import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../core/constants/legal_constants.dart';
import '../legal/legal_document_screen.dart';
import '../membership/membership_screen.dart';
import '../../widgets/legal_footer.dart';
import '../../widgets/swimiq_header.dart';
import '../../services/auth_service.dart';

/// Account and app settings — Milestone 4.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const appVersion = '1.0.0';

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    await ref.read(authServiceProvider).signOut();
    ref.read(activeSwimmerProvider.notifier).state = null;
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmLogOut(WidgetRef ref, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out?'),
          content: const Text(
            'Are you sure you want to log out?\n'
            'Your SwimIQ data is securely saved and will be available the next '
            'time you sign in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await _signOut(ref, context);
    }
  }

  Future<void> _openWebLegalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final swimmer = ref.watch(activeSwimmerProvider);
    final profile = ref.watch(swimmerDataProvider).value?.profile;

    return Scaffold(
      appBar: AppBar(
        title: const SwimIqScreenAppBarTitle('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Display name'),
                  subtitle: Text(
                    profile?.displayName ??
                        user?.userMetadata?['display_name']?.toString() ??
                        swimmer ??
                        '—',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? '—'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pool),
                  title: const Text('Swimmer key'),
                  subtitle: Text(swimmer ?? '—'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Membership',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Plans & billing'),
              subtitle: const Text(
                'Basic, Pro, and Elite — coach preview includes Elite AI sneak peek.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MembershipScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Legal & privacy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a document to read it in the app, or open the web version.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Read in app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LegalDocumentScreen(
                          document: LegalDocumentType.privacyPolicy,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Privacy Policy (web)'),
                  subtitle: Text(LegalConstants.privacyPolicyWebUrl),
                  onTap: () => _openWebLegalUrl(
                    context,
                    LegalConstants.privacyPolicyWebUrl,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  subtitle: const Text('Read in app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LegalDocumentScreen(
                          document: LegalDocumentType.termsOfService,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Terms of Service (web)'),
                  subtitle: Text(LegalConstants.termsOfServiceWebUrl),
                  onTap: () => _openWebLegalUrl(
                    context,
                    LegalConstants.termsOfServiceWebUrl,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('AI & Data Disclosure'),
                  subtitle: const Text('Read in app · required for SwimIQ AI'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LegalDocumentScreen(
                          document: LegalDocumentType.aiDataDisclosure,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('AI & Data Disclosure (web)'),
                  subtitle: Text(LegalConstants.aiDisclosureWebUrl),
                  onTap: () => _openWebLegalUrl(
                    context,
                    LegalConstants.aiDisclosureWebUrl,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('Support'),
                  subtitle: Text(LegalConstants.supportEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openWebLegalUrl(
                    context,
                    LegalConstants.supportMailtoUrl,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Delete Account'),
                  subtitle: const Text('Request deletion of your account & data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openWebLegalUrl(
                    context,
                    LegalConstants.deleteAccountWebUrl,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'App',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('SwimIQ $appVersion'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.waves),
                  title: Text('Copyright'),
                  subtitle: Text(AppConstants.copyright),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const LegalFooter(),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _confirmLogOut(ref, context),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
