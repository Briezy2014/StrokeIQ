import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/env.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

/// Initializes the app and routes based on authentication state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!Env.isConfigured) {
      setState(() {
        _errorMessage =
            'Supabase is not configured. Copy .env.example to .env or use '
            '--dart-define.';
      });
      return;
    }

    try {
      await SupabaseService.initialize();

      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();
      if (authProvider.status == AuthStatus.unknown) {
        await authProvider.initialize();
      }

      if (!mounted) return;

      // Brief splash delay for branding, then let router redirect.
      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      final nextRoute = authProvider.isAuthenticated
          ? AppRoutes.home
          : AppRoutes.login;

      context.go(nextRoute);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not connect to Supabase. Check your credentials.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent,
              AppColors.accentLight,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/swimiq_logo.png',
                  width: 220,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.pool,
                    size: 96,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    '${AppStrings.versionLabel} · Connecting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
