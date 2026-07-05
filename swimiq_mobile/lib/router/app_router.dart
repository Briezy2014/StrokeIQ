import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../screens/meets/meet_results_screen.dart';
import '../screens/personal_bests/personal_bests_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/standards/usa_standards_screen.dart';
import '../screens/training/training_log_screen.dart';
import '../screens/video_lab/video_lab_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final location = state.matchedLocation;

      final isSplash = location == '/splash';
      final isAuthRoute = location == '/login' || location == '/signup';

      if (isSplash) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home/personal-bests',
        builder: (context, state) => const PersonalBestsScreen(),
      ),
      GoRoute(
        path: '/home/video-lab',
        builder: (context, state) => const VideoLabScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/training',
                builder: (context, state) => const TrainingLogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/meets',
                builder: (context, state) => const MeetResultsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/standards',
                builder: (context, state) => const UsaStandardsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
