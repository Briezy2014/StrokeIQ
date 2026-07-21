import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'providers/swimmer_data_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/update_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/swimiq_logo.dart';
import 'widgets/swimiq_header.dart';

/// Routes between splash, auth, and the main app based on session state.
class SwimIqApp extends ConsumerStatefulWidget {
  const SwimIqApp({super.key});

  @override
  ConsumerState<SwimIqApp> createState() => _SwimIqAppState();
}

class _SwimIqAppState extends ConsumerState<SwimIqApp> {
  bool _showSignup = false;
  bool _passwordRecovery = false;

  void _toggleAuthMode() {
    setState(() => _showSignup = !_showSignup);
  }

  void _finishPasswordRecovery() {
    setState(() => _passwordRecovery = false);
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
        error: (error, _) => _AuthRecoveryScreen(
          message: error.toString(),
          onRetry: () async {
            final auth = ref.read(authServiceProvider);
            final refreshed = await auth.tryRefreshSession();
            if (!refreshed) {
              try {
                await auth.signOutLocal();
              } catch (_) {}
            }
            ref.invalidate(authStateProvider);
          },
          onContinueToLogin: () async {
            try {
              await ref.read(authServiceProvider).signOutLocal();
            } catch (_) {}
            ref.invalidate(authStateProvider);
          },
        ),
        data: (authState) {
          final recoveryFromUrl = kIsWeb &&
              (Uri.base.queryParameters['type'] == 'recovery' ||
                  Uri.base.fragment.contains('type=recovery'));
          if (authState.event == AuthChangeEvent.passwordRecovery ||
              recoveryFromUrl) {
            if (!_passwordRecovery) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _passwordRecovery = true);
              });
            }
          }

          final session = authState.session;
          if (session == null) {
            return _showSignup
                ? SignupScreen(onSwitchToLogin: _toggleAuthMode)
                : LoginScreen(onSwitchToSignup: _toggleAuthMode);
          }

          if (_passwordRecovery ||
              authState.event == AuthChangeEvent.passwordRecovery ||
              recoveryFromUrl) {
            return UpdatePasswordScreen(onFinished: _finishPasswordRecovery);
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
              final coachError = await ref
                  .read(subscriptionStateProvider.notifier)
                  .redeemPendingCoachCodeIfAny();
              if (coachError != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(coachError)),
                );
              }
            });
            return const SplashScreen();
          }

          if (kIsWeb && Uri.base.queryParameters['checkout'] == 'success') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(subscriptionStateProvider.notifier).refreshFromServer();
            });
          }
          if (kIsWeb && Uri.base.queryParameters['checkout'] == 'cancel') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checkout canceled — no charge was made.'),
                ),
              );
            });
          }

          return const HomeScreen();
        },
      ),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SwimIqFullLockup(width: 200, borderRadius: 16),
              const SizedBox(height: 20),
              Text(
                'SwimIQ is not connected yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                kDebugMode
                    ? 'Local Chrome builds need Supabase keys.\n\n'
                      '1. Copy .env.example to .env and add your keys\n'
                      '2. Run: flutter pub get\n'
                      '3. Run: flutter run -d chrome --dart-define-from-file=.env\n\n'
                      'Or double-click LAUNCH-CHROME.bat / REVIEW-NOW.bat'
                    : 'This build is missing its cloud connection settings. '
                      'If you installed SwimIQ from the App Store, contact '
                      'support@swimiqapp.com.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const SwimIqCopyrightLine(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recoverable auth/network failure — never confuse this with missing .env keys.
class _AuthRecoveryScreen extends StatelessWidget {
  const _AuthRecoveryScreen({
    required this.message,
    required this.onRetry,
    required this.onContinueToLogin,
  });

  final String message;
  final Future<void> Function() onRetry;
  final Future<void> Function() onContinueToLogin;

  @override
  Widget build(BuildContext context) {
    final friendly = _friendlyAuthError(message);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SwimIqFullLockup(width: 200, borderRadius: 16),
              const SizedBox(height: 20),
              Text(
                'Connection hiccup',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                friendly,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.85),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => onRetry(),
                child: const Text('Retry connection'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => onContinueToLogin(),
                child: const Text('Continue to sign in'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.55),
                      ),
                ),
              ],
              const SizedBox(height: 24),
              const SwimIqCopyrightLine(),
            ],
          ),
        ),
      ),
    );
  }

  static String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('failed to fetch') ||
        lower.contains('authretryablefetchexception') ||
        lower.contains('clientexception') ||
        lower.contains('socket') ||
        lower.contains('network')) {
      return 'SwimIQ could not refresh your session (network blip or '
          'Supabase temporarily unreachable).\n\n'
          'Check Wi‑Fi, then Retry — or Continue to sign in again.';
    }
    return 'SwimIQ hit a temporary sign-in problem.\n\n'
        'Tap Retry, or Continue to sign in again.';
  }
}
