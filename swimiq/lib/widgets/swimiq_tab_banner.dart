import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'swimiq_logo.dart';

/// Full-width brand strip below the app bar on every tab except Dashboard.
class SwimIqTabBanner extends StatelessWidget {
  const SwimIqTabBanner({
    super.key,
    required this.tabIndex,
  });

  final int tabIndex;

  static String? moduleLabelForTab(int index) {
    return switch (index) {
      HomeTab.personalBests => 'Personal Bests',
      HomeTab.trainingLog => 'Training Log',
      HomeTab.goals => 'Goals',
      HomeTab.videoLab => 'Video Lab',
      HomeTab.passport => 'Recruiting Passport',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final module = moduleLabelForTab(tabIndex);
    if (module == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF020812),
              Color(0xFF0B2D4D),
              Color(0xFF0B5CAD),
              Color(0xFF009CFF),
            ],
            stops: [0.0, 0.35, 0.72, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeep.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SwimIqBannerSplashPainter(
                    seed: tabIndex.toDouble(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SwimIqCompactMark(size: 54, borderRadius: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const SwimIqWordmark(fontSize: 20),
                              _ModuleChip(label: module),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.brandTagline.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  height: 1.25,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppConstants.brandTaglineShort,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.accent.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _SwimIqBannerSplashPainter extends CustomPainter {
  _SwimIqBannerSplashPainter({required this.seed});

  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed.round());
    for (var i = 0; i < 14; i++) {
      final radius = 8.0 + random.nextDouble() * 28;
      final center = Offset(
        size.width * (0.45 + random.nextDouble() * 0.55),
        size.height * random.nextDouble(),
      );
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.04 + random.nextDouble() * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius, paint);
    }

    final streak = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.55, 0, size.width * 0.4, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), streak);
  }

  @override
  bool shouldRepaint(covariant _SwimIqBannerSplashPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
