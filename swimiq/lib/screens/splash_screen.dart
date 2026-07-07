import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'swimiq_brand_typography.dart';
import 'swimiq_logo.dart';

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
              Color(0xFF0B2D4D),
              Color(0xFF0B5CAD),
              Color(0xFF009CFF),
              Color(0xFF5CC8FF),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SwimIqLogo(size: 128, borderRadius: 28),
              const SizedBox(height: 24),
              const SwimIqWordmark(fontSize: 40, onDark: true),
              const SizedBox(height: 16),
              const SwimIqTagline(
                fontSize: 22,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              const SwimIqFounderLine(
                color: Colors.white70,
                fontSize: 14,
              ),
              const SizedBox(height: 52),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
