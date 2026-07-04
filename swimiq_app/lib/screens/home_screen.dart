import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/app_providers.dart';
import 'add_session_screen.dart';
import 'athlete_passport_screen.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'meet_results_screen.dart';
import 'personal_bests_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _titles = [
    'Dashboard',
    'Personal Bests',
    'Add Session',
    'Goals',
    'Meet Results',
    'Athlete Passport',
  ];

  static const _screens = [
    DashboardScreen(),
    PersonalBestsScreen(),
    AddSessionScreen(),
    GoalsScreen(),
    MeetResultsScreen(),
    AthletePassportScreen(),
  ];

  Future<void> _switchSwimmer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch swimmer?'),
        content: const Text('You will return to the swimmer login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(activeSwimmerProvider.notifier).clearSwimmer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final swimmer = ref.watch(activeSwimmerProvider) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_titles[_selectedIndex]),
            Text(
              swimmer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SwimIQTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch swimmer',
            onPressed: _switchSwimmer,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'PBs',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_score_outlined),
            selectedIcon: Icon(Icons.sports_score_rounded),
            label: 'Meets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Passport',
          ),
        ],
      ),
    );
  }
}
