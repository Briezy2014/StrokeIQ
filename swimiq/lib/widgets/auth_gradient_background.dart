import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Shared gradient background used on splash and auth screens.
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child: SafeArea(child: child),
    );
  }
}
