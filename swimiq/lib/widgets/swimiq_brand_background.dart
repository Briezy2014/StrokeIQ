import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Water-gradient shell for main app screens — replaces flat white backgrounds.
class SwimIqBrandBackground extends StatelessWidget {
  const SwimIqBrandBackground({
    super.key,
    required this.child,
    this.showWaves = true,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final bool showWaves;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD4EEFF),
            Color(0xFFEEF9FF),
            Color(0xFFF7FCFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (showWaves) const Positioned.fill(child: _WaterWaveLayer()),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Branded app bar gradient strip behind transparent [AppBar].
class SwimIqBrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SwimIqBrandedAppBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x330B2D4D),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WaterWaveLayer extends StatelessWidget {
  const _WaterWaveLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(
        color: AppColors.accent.withValues(alpha: 0.07),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final waveHeight = 28.0;
    final baseY = size.height * 0.18;

    path.moveTo(0, baseY);
    for (var x = 0.0; x <= size.width; x++) {
      final y = baseY +
          math.sin((x / size.width) * math.pi * 4) * waveHeight * 0.35;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);

    final path2 = Path();
    final baseY2 = size.height * 0.72;
    path2.moveTo(0, baseY2);
    for (var x = 0.0; x <= size.width; x++) {
      final y = baseY2 +
          math.sin((x / size.width) * math.pi * 3 + 1) * waveHeight * 0.5;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint..color = color.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
