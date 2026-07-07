import 'package:flutter/material.dart';

/// Deep-pool gradient for splash and auth screens.
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
            Color(0xFF0B2D4D),
            Color(0xFF0B5CAD),
            Color(0xFF009CFF),
            Color(0xFF38B6FF),
          ],
          stops: [0.0, 0.4, 0.75, 1.0],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
