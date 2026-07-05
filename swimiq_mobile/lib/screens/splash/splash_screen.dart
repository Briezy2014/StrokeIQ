import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/swimiq_logo.dart';

/// Shows SwimIQ branding briefly, then routes to login or dashboard.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }

    final isLoggedIn = ref.read(authRefreshNotifierProvider).isLoggedIn;
    if (isLoggedIn) {
      context.go('/home/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwimIqColors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SwimIqLogo(
                  variant: SwimIqLogoVariant.brandingFull,
                  width: 300,
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  color: SwimIqColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
