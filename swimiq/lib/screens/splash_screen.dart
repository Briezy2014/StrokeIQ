import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/swimiq_logo.dart';

/// Branded splash while auth/session state loads.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SwimIqLogo(size: 120, borderRadius: 28),
              const SizedBox(height: 16),
              const SwimIqWordmark(fontSize: 32),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
