import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../widgets/swimiq_logo.dart';
import '../widgets/swimiq_header.dart';

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
            children: [
              const Spacer(),
              const SwimIqFullLockup(width: 280, borderRadius: 24),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white),
              const Spacer(),
              const SwimIqCopyrightLine(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
