import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final swimmer = ref.watch(activeSwimmerProvider);
    final profile = ref.watch(swimmerDataProvider).value?.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
            'Passport',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Edit Athlete Passport'),
              subtitle: const Text('Birthday, gender, photo, team, strokes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(homeTabIndexProvider.notifier).state = HomeTab.passport;
                Navigator.of(context).pop();
              },
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
                  title: Text('Tagline'),
                  subtitle: Text(AppConstants.tagline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _signOut(ref, context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
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
