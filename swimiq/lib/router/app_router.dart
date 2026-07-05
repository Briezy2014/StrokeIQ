import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_placeholder_screen.dart';
import '../screens/splash_screen.dart';

/// Central router with auth-aware redirects.
class AppRouter {
  AppRouter(this._authProvider);

  final AuthProvider _authProvider;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _authProvider,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final status = _authProvider.status;

    if (status == AuthStatus.unknown) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final isAuthRoute =
        location == AppRoutes.login || location == AppRoutes.signup;

    if (status == AuthStatus.unauthenticated) {
      if (location == AppRoutes.splash || isAuthRoute) return null;
      return AppRoutes.login;
    }

    // Authenticated
    if (location == AppRoutes.splash || isAuthRoute) {
      return AppRoutes.home;
    }

    return null;
  }
}
