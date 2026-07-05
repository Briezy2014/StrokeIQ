import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/meets/meets_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/training/add_session_screen.dart';
import '../features/training/training_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

enum AppRoute {
  splash('/'),
  login('/login'),
  signup('/signup'),
  dashboard('/dashboard'),
  training('/training'),
  trainingAdd('/training/add'),
  meets('/meets'),
  goals('/goals'),
  profile('/profile'),
  settings('/settings');

  const AppRoute(this.path);

  final String path;
}

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.splash.path,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onSplash = location == AppRoute.splash.path;
      final onAuthRoute =
          location == AppRoute.login.path || location == AppRoute.signup.path;

      if (onSplash) return null;

      if (!isAuthenticated) {
        return onAuthRoute ? null : AppRoute.login.path;
      }

      if (onAuthRoute) {
        return AppRoute.dashboard.path;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.signup.path,
        builder: (context, state) => const SignUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.dashboard.path,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.training.path,
                builder: (context, state) => const TrainingScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddSessionScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.meets.path,
                builder: (context, state) => const MeetsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.goals.path,
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings.path,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(child: Text(state.error?.toString() ?? 'Unknown error')),
    ),
  );
});

/// Rebuilds [GoRouter] when Riverpod auth state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<bool>(isAuthenticatedProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
