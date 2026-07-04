import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../widgets/swimiq_header.dart';
import 'add_session/add_session_screen.dart';
import 'athlete_passport/athlete_passport_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'meet_results/meet_results_screen.dart';
import 'personal_bests/personal_bests_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _switchSwimmer() {
    ref.read(activeSwimmerProvider.notifier).state = null;
  }

  Future<void> _refresh() async {
    await ref.read(swimmerDataProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final swimmer = ref.watch(activeSwimmerProvider)!;
    final dataAsync = ref.watch(swimmerDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SwimIQ'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: _switchSwimmer,
            child: const Text('Switch swimmer'),
          ),
        ],
      ),
      body: Column(
        children: [
          MaterialBanner(
            content: Text('Current swimmer: $swimmer'),
            backgroundColor: Colors.green.shade50,
            actions: const [SizedBox.shrink()],
          ),
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Could not load swimmer data: $error'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                if (data == null) {
                  return const Center(child: Text('No swimmer selected.'));
                }

                final screens = [
                  DashboardScreen(data: data),
                  PersonalBestsScreen(data: data),
                  const AddSessionScreen(),
                  GoalsScreen(data: data),
                  MeetResultsScreen(data: data),
                  AthletePassportScreen(data: data),
                ];

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: screens[_selectedIndex],
                );
              },
            ),
          ),
          const SwimIqFooter(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'PBs',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.stadium_outlined),
            selectedIcon: Icon(Icons.stadium),
            label: 'Meets',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Passport',
          ),
        ],
      ),
    );
  }
}
