import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/gamification/swimiq_badges.dart';
import '../core/gamification/swimiq_daily_progress.dart';
import '../core/theme/app_theme.dart';

class SwimIqRopeClimbCard extends StatelessWidget {
  const SwimIqRopeClimbCard({
    super.key,
    required this.daily,
    required this.badges,
  });

  final SwimIqDailyProgress daily;
  final List<SwimIqBadge> badges;

  @override
  Widget build(BuildContext context) {
    final earned = badges.where((badge) => badge.isEarned).toList();
    final locked = badges.where((badge) => !badge.isEarned).take(6).toList();
    final climbPercent = (daily.ropeClimbFraction * 100).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🪢', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Rope Climb',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeep,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${daily.todayPoints}/100 pts today',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your SwimIQ Score (${daily.overallSwimIqScore}) sets your height on the rope. '
              'Log today\'s work (+${daily.todayPoints} pts) to climb higher.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: _RopeClimbScene(climbFraction: daily.ropeClimbFraction),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$climbPercent% up the rope',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Badges earned (${earned.length}/${badges.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            if (earned.isEmpty)
              Text(
                'Log a session today to earn your first badge and start climbing.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final badge in earned)
                    _BadgeChip(badge: badge, earned: true),
                ],
              ),
            if (locked.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Next badges to unlock',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final badge in locked)
                    _BadgeChip(badge: badge, earned: false),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.earned});

  final SwimIqBadge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: earned
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              badge.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: earned ? AppColors.primaryDeep : Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RopeGeometry {
  const _RopeGeometry({
    required this.ropeX,
    required this.ropeTop,
    required this.ropeBottom,
    required this.poolTop,
  });

  final double ropeX;
  final double ropeTop;
  final double ropeBottom;
  final double poolTop;

  double progressY(double climbFraction) =>
      ropeBottom - ((ropeBottom - ropeTop) * climbFraction);

  static _RopeGeometry fromSize(Size size) {
    final poolTop = size.height * 0.72;
    return _RopeGeometry(
      ropeX: size.width * 0.22,
      ropeTop: size.height * 0.06,
      ropeBottom: poolTop + 6,
      poolTop: poolTop,
    );
  }
}

class _RopeClimbScene extends StatelessWidget {
  const _RopeClimbScene({required this.climbFraction});

  final double climbFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _RopeGeometry.fromSize(size);
        final progressY = geometry.progressY(climbFraction);
        const avatarSize = 48.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: size,
              painter: _RopeClimbPainter(
                climbFraction: climbFraction,
                geometry: geometry,
              ),
            ),
            Positioned(
              left: geometry.ropeX - avatarSize * 0.42,
              top: (progressY - avatarSize * 0.88).clamp(
                geometry.ropeTop - 8,
                geometry.ropeBottom - avatarSize * 0.35,
              ),
              child: _ClimbingAvatar(
                climbFraction: climbFraction,
                size: avatarSize,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClimbingAvatar extends StatelessWidget {
  const _ClimbingAvatar({
    required this.climbFraction,
    required this.size,
  });

  final double climbFraction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = (120 * climbFraction).clamp(0, 120).toDouble();
    final wiggle = math.sin(climbFraction * math.pi * 4) * 0.04;

    return Transform.rotate(
      angle: wiggle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HSLColor.fromAHSL(1, hue, 0.75, 0.55).toColor(),
              AppColors.primary,
            ],
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _ClimbingSwimmerPainter(),
        ),
      ),
    );
  }
}

/// Vertical climber with arms reaching up the rope (not a sideways crawl).
class _ClimbingSwimmerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..color = Colors.white;

    // Head
    canvas.drawCircle(Offset(cx, h * 0.24), w * 0.11, fillPaint);

    // Torso
    canvas.drawLine(
      Offset(cx, h * 0.34),
      Offset(cx, h * 0.62),
      bodyPaint,
    );

    // Arms reaching upward on the rope
    final leftArm = Path()
      ..moveTo(cx, h * 0.38)
      ..quadraticBezierTo(cx - w * 0.08, h * 0.18, cx - w * 0.02, h * 0.08);
    final rightArm = Path()
      ..moveTo(cx, h * 0.42)
      ..quadraticBezierTo(cx + w * 0.1, h * 0.2, cx + w * 0.04, h * 0.06);
    canvas.drawPath(leftArm, bodyPaint);
    canvas.drawPath(rightArm, bodyPaint);

    // Legs bent as if bracing on the rope
    final leftLeg = Path()
      ..moveTo(cx, h * 0.62)
      ..quadraticBezierTo(cx - w * 0.14, h * 0.78, cx - w * 0.06, h * 0.9);
    final rightLeg = Path()
      ..moveTo(cx, h * 0.62)
      ..quadraticBezierTo(cx + w * 0.12, h * 0.8, cx + w * 0.08, h * 0.92);
    canvas.drawPath(leftLeg, bodyPaint);
    canvas.drawPath(rightLeg, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RopeClimbPainter extends CustomPainter {
  _RopeClimbPainter({
    required this.climbFraction,
    required this.geometry,
  });

  final double climbFraction;
  final _RopeGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final poolRect = Rect.fromLTWH(
      0,
      geometry.poolTop,
      size.width,
      size.height - geometry.poolTop,
    );
    final poolPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x88009CFF),
          AppColors.primaryDeep,
        ],
      ).createShader(poolRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(poolRect, const Radius.circular(18)),
      poolPaint,
    );

    // Soft water shimmer — not heavy horizontal stripes.
    for (var i = 0; i < 3; i++) {
      final y = poolRect.top + 14 + (i * 18);
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y + 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..strokeWidth = 1.5,
      );
    }

    final ropeColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFEAB308),
      const Color(0xFF22C55E),
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
    ];

    final segmentHeight =
        (geometry.ropeBottom - geometry.ropeTop) / ropeColors.length;
    for (var i = 0; i < ropeColors.length; i++) {
      canvas.drawLine(
        Offset(geometry.ropeX, geometry.ropeTop + segmentHeight * i),
        Offset(geometry.ropeX, geometry.ropeTop + segmentHeight * (i + 1)),
        Paint()
          ..color = ropeColors[i]
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
    }

    final progressY = geometry.progressY(climbFraction);
    canvas.drawCircle(
      Offset(geometry.ropeX, progressY),
      7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(geometry.ropeX, progressY),
      10,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RopeClimbPainter oldDelegate) =>
      oldDelegate.climbFraction != climbFraction;
}
