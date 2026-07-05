import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../widgets/swimiq_header.dart';
import 'add_session/add_session_screen.dart';
import 'athlete_passport/athlete_passport_v2_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'meet_results/meet_results_screen.dart';
import 'personal_bests/personal_bests_screen.dart';
import 'video_lab/video_lab_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Widget _screenAt(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const PersonalBestsScreen();
      case 2:
        return const AddSessionScreen();
      case 3:
        return const GoalsScreen();
      case 4:
        return const MeetResultsScreen();
      case 5:
        return const VideoLabScreen();
      case 6:
        return const AthletePassportV2Screen();
      default:
        return const DashboardScreen();
    }
  }

  void _switchSwimmer() {
    ref.read(activeSwimmerProvider.notifier).state = null;
  }

  Future<void> _refresh() async {
    await ref.read(swimmerDataProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final swimmer = ref.watch(activeSwimmerProvider)!;
    final selectedIndex = ref.watch(homeTabIndexProvider);

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
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Video',
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
