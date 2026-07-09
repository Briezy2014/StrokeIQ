import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../core/theme/app_theme.dart';
import '../core/web/public_web_routes.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
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
    final publicRoute =
        kIsWeb ? PublicWebRoute.fromUri(Uri.base) : null;
    if (publicRoute != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: PublicWebRouteScreen(route: publicRoute),
      );
    }

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
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              ref.read(activeSwimmerProvider.notifier).state = swimmerKey;
              final user = session.user;
              await ref.read(swimmerDataProvider.notifier).ensureSwimmerProfileLinked(
                    swimmerName: swimmerKey,
                    preferredName:
                        user.userMetadata?['display_name'] as String?,
                    email: user.email,
                  );
              await ref.read(subscriptionStateProvider.notifier).refreshFromServer();
            });
            return const SplashScreen();
          }

          if (kIsWeb && Uri.base.queryParameters['checkout'] == 'success') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(subscriptionStateProvider.notifier).refreshFromServer();
            });
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
                'SwimIQ is not connected yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    'This build is missing its cloud connection settings. '
                    'If you installed SwimIQ from the App Store, contact '
                    'support@swimiqapp.com.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
