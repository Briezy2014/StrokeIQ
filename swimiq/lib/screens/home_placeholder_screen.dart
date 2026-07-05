import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';

/// Temporary home screen until Milestone 3/4 V1 screens are built.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pool, size: 72),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${auth.displayName}!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You are signed in. V1 screens (dashboard, training log, '
                'goals, and more) arrive in Milestones 3–4.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                auth.currentUser?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
