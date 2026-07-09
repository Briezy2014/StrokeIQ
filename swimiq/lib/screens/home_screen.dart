import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/models/subscription_plan.dart';
import '../core/services/subscription_service.dart';
import '../core/subscription/subscription_capabilities.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../widgets/swimiq_tab_banner.dart';
import '../widgets/swimiq_header.dart';
import '../widgets/subscription_upgrade_panel.dart';
import 'athlete_passport/athlete_passport_v2_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'membership/membership_screen.dart';
import 'personal_bests/personal_bests_screen.dart';
import 'settings/settings_screen.dart';
import 'training_log/training_log_screen.dart';
import 'video_lab/video_lab_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _proTeaser = [
    'Official PBs, meet results & USA Swimming standards',
    'Athlete Passport & Recruiting Snapshot',
    'Video Lab (upload & organize videos)',
    'AI Dryland Coach — strength, core & mobility',
  ];

  Widget _proGate(Widget child) {
    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.pro,
      title: 'Unlock SwimIQ Pro',
      message: SubscriptionCapabilities.proGateMessage(),
      teaserFeatures: _proTeaser,
      child: child,
    );
  }

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
      case HomeTab.videoLab:
        return _proGate(const VideoLabScreen());
      case HomeTab.passport:
        return _proGate(const AthletePassportV2Screen());
      default:
        return const DashboardScreen();
    }
  }

  bool _tabLocked(int index, SubscriptionState? subscription) {
    if (AppConstants.unlockAllTabsForPreview) return false;
    return !SubscriptionCapabilities.canAccessHomeTab(index, subscription);
  }

  void _onTabSelected(int index) {
    final subscription = ref.read(subscriptionStateProvider).value;
    if (_tabLocked(index, subscription)) {
      final minTier = SubscriptionCapabilities.minimumTierForHomeTab(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            minTier == SubscriptionTier.elite
                ? SubscriptionCapabilities.eliteGateMessage(subscription!)
                : SubscriptionCapabilities.proGateMessage(),
          ),
          action: SnackBarAction(
            label: 'Plans',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MembershipScreen(),
                ),
              );
            },
          ),
        ),
      );
      return;
    }
    ref.read(homeTabIndexProvider.notifier).state = index;
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
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
    final subscription = ref.watch(subscriptionStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 8,
        centerTitle: false,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedIndex != HomeTab.dashboard)
            SwimIqTabBanner(tabIndex: selectedIndex),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _screenAt(selectedIndex),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          _dest(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', HomeTab.dashboard, subscription),
          _dest(Icons.emoji_events_outlined, Icons.emoji_events, 'PBs', HomeTab.personalBests, subscription),
          _dest(Icons.list_alt_outlined, Icons.list_alt, 'Log', HomeTab.trainingLog, subscription),
          _dest(Icons.flag_outlined, Icons.flag, 'Goals', HomeTab.goals, subscription),
          _dest(Icons.videocam_outlined, Icons.videocam, 'Video', HomeTab.videoLab, subscription),
          _dest(Icons.badge_outlined, Icons.badge, 'Passport', HomeTab.passport, subscription),
        ],
      ),
    );
  }

  NavigationDestination _dest(
    IconData icon,
    IconData selected,
    String label,
    int index,
    SubscriptionState? subscription,
  ) {
    final locked = _tabLocked(index, subscription);
    return NavigationDestination(
      icon: Icon(locked ? Icons.lock_outline : icon),
      selectedIcon: Icon(locked ? Icons.lock : selected),
      label: label,
    );
  }
}
