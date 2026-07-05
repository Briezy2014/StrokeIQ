import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../services/auth_service.dart';
import '../widgets/swimiq_header.dart';
import 'add_session/add_session_screen.dart';
import 'athlete_passport/athlete_passport_v2_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'meet_results/meet_results_screen.dart';
import 'personal_bests/personal_bests_screen.dart';
import 'settings/settings_screen.dart';
import 'training_log/training_log_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Widget _screenAt(int index) {
    switch (index) {
      case HomeTab.dashboard:
        return const DashboardScreen();
      case HomeTab.personalBests:
        return const PersonalBestsScreen();
      case HomeTab.trainingLog:
        return const TrainingLogScreen();
      case HomeTab.goals:
        return const GoalsScreen();
      case HomeTab.meetResults:
        return const MeetResultsScreen();
      case HomeTab.passport:
        return const AthletePassportV2Screen();
      default:
        return const DashboardScreen();
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openAddSession() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddSessionScreen(),
      ),
    );
  }

  Future<void> _refresh() async {
    await ref.read(swimmerDataProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final swimmer = ref.watch(activeSwimmerProvider)!;
    final selectedIndex = ref.watch(homeTabIndexProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: SwimIqAppBarTitle(subtitle: swimmer),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: selectedIndex == HomeTab.trainingLog
          ? FloatingActionButton.extended(
              onPressed: _openAddSession,
              icon: const Icon(Icons.add),
              label: const Text('Log Session'),
            )
          : null,
      body: Column(
        children: [
          MaterialBanner(
            content: Text(
              user?.email != null
                  ? 'Signed in as ${user!.email}'
                  : 'Swimmer: $swimmer',
            ),
            backgroundColor: Colors.green.shade50,
            actions: const [SizedBox.shrink()],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _screenAt(selectedIndex),
            ),
          ),
          const SwimIqFooter(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(homeTabIndexProvider.notifier).state = index;
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
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Log',
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
