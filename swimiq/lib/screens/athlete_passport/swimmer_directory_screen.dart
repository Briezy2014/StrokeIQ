import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/swimmer_profile.dart';
import '../../providers/app_providers.dart';
import 'public_swimmer_profile_screen.dart';

final swimmerDirectorySearchProvider =
    FutureProvider.family<List<SwimmerProfile>, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.length < 2) return const [];
  return ref.read(swimIqRepositoryProvider).searchPublicProfiles(trimmed);
});

class SwimmerDirectoryScreen extends ConsumerStatefulWidget {
  const SwimmerDirectoryScreen({super.key});

  @override
  ConsumerState<SwimmerDirectoryScreen> createState() =>
      _SwimmerDirectoryScreenState();
}

class _SwimmerDirectoryScreenState extends ConsumerState<SwimmerDirectoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String value) {
    setState(() => _query = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.length >= 2
        ? ref.watch(swimmerDirectorySearchProvider(_query))
        : const AsyncValue<List<SwimmerProfile>>.data([]);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a swimmer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Look up a teammate or recruit by name. Only swimmers who turn on '
            '"Public passport" in their Passport tab appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search name',
              hintText: 'Example: Aspyn Williams',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _runSearch(_searchController.text),
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _runSearch,
            onChanged: (value) {
              if (value.trim().length >= 2) {
                _runSearch(value);
              }
            },
          ),
          const SizedBox(height: 20),
          results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(
              'Could not search swimmers. If this persists, your Supabase '
              'policy may need to allow reading public profiles.\n$error',
            ),
            data: (profiles) {
              if (_query.length < 2) {
                return const Text('Type at least 2 letters to search.');
              }
              if (profiles.isEmpty) {
                return const Text(
                  'No public passports matched. The swimmer may need to enable '
                  'Public passport in Passport → Edit.',
                );
              }
              return Column(
                children: profiles
                    .map(
                      (profile) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(profile.displayName),
                          subtitle: Text(
                            [
                              if (profile.team != null && profile.team!.isNotEmpty)
                                profile.team!,
                              if (profile.school != null &&
                                  profile.school!.isNotEmpty)
                                profile.school!,
                              if (profile.graduationYear != null)
                                'Class of ${profile.graduationYear}',
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PublicSwimmerProfileScreen(
                                  profile: profile,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
