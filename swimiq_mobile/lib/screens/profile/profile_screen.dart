import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/app_providers.dart';

final swimmerProfileProvider = FutureProvider.autoDispose((ref) async {
  final swimmerName = ref.watch(currentSwimmerNameProvider);
  if (swimmerName == null || swimmerName.isEmpty) {
    return null;
  }

  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfileBySwimmerName(swimmerName);
});

/// Athlete Passport profile view (read-only for now).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(swimmerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Passport'),
        actions: [
          IconButton(
            onPressed: () => context.push('/home/profile/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load profile: $error'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No swimmer profile found yet. It should be created '
                  'automatically when you sign up.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      SwimIqColors.primary,
                      SwimIqColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.pool_rounded,
                        size: 40,
                        color: SwimIqColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.team ?? 'Team not added yet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileTile(
                label: 'Swimmer code',
                value: profile.swimmerName,
              ),
              _ProfileTile(
                label: 'Coach',
                value: profile.coachName ?? 'Not added yet',
              ),
              _ProfileTile(
                label: 'Primary stroke',
                value: profile.primaryStroke ?? 'Not added yet',
              ),
              _ProfileTile(
                label: 'Favorite event',
                value: profile.favoriteEvent ?? 'Not added yet',
              ),
              _ProfileTile(
                label: 'School',
                value: profile.school ?? 'Not added yet',
              ),
              const SizedBox(height: 8),
              const Text(
                'Full profile editing will be added in a later milestone.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
