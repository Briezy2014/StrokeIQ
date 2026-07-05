import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

/// Routes between splash, auth, and the main app based on session state.
class SwimIqApp extends ConsumerStatefulWidget {
  const SwimIqApp({super.key});

  @override
  ConsumerState<SwimIqApp> createState() => _SwimIqAppState();
}

class _SwimIqAppState extends ConsumerState<SwimIqApp> {
  bool _showSignup = false;

  void _toggleAuthMode() {
    setState(() => _showSignup = !_showSignup);
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _ConfigErrorScreen(),
      );
    }

    final authAsync = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'SwimIQ',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: authAsync.when(
        loading: () => const SplashScreen(),
        error: (error, _) => _ConfigErrorScreen(message: error.toString()),
        data: (authState) {
          final session = authState.session;
          if (session == null) {
            return _showSignup
                ? SignupScreen(onSwitchToLogin: _toggleAuthMode)
                : LoginScreen(onSwitchToSignup: _toggleAuthMode);
          }

          final swimmerKey = AuthService.swimmerKeyForUser(session.user);
          final activeSwimmer = ref.watch(activeSwimmerProvider);

          if (activeSwimmer != swimmerKey) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(activeSwimmerProvider.notifier).state = swimmerKey;
            });
            return const SplashScreen();
          }

          return const HomeScreen();
        },
      ),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings, size: 64),
              const SizedBox(height: 16),
              Text(
                'Supabase is not configured',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    'Copy swimiq/.env.example to swimiq/.env and add your '
                    'SUPABASE_URL and SUPABASE_ANON_KEY.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
