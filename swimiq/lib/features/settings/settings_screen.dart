import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../router/app_router.dart';
import '../shared/placeholder_body.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PlaceholderBody(
          icon: Icons.settings,
          title: 'Settings',
          message: 'Manage your SwimIQ account and app preferences.',
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Signed in as'),
            subtitle: Text(user?.email ?? 'Unknown'),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
            if (context.mounted) context.go(AppRoute.login.path);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
        ),
        const SizedBox(height: 24),
        Text(
          '${AppConstants.appName} · ${AppConstants.versionLabel}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
