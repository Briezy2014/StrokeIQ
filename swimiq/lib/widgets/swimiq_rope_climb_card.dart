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
                    '${daily.todayPoints}/100 pts',
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
              'Climb the rope with your SwimIQ Score (${daily.overallSwimIqScore}). '
              'Log training today for bonus points (${daily.todayPoints}/100).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: _RopeClimbScene(climbFraction: daily.climbFraction),
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

class _RopeClimbScene extends StatelessWidget {
  const _RopeClimbScene({required this.climbFraction});

  final double climbFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _RopeClimbPainter(climbFraction: climbFraction),
          child: Align(
            alignment: Alignment(
              -0.72,
              0.95 - (climbFraction * 1.75),
            ),
            child: _AvatarBubble(climbFraction: climbFraction),
          ),
        );
      },
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.climbFraction});

  final double climbFraction;

  @override
  Widget build(BuildContext context) {
    final hue = (120 * climbFraction).clamp(0, 120).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
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
          child: const Center(
            child: Text('🏊', style: TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${(climbFraction * 100).round()}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
      ],
    );
  }
}

class _RopeClimbPainter extends CustomPainter {
  _RopeClimbPainter({required this.climbFraction});

  final double climbFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final poolRect = Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28);
    final poolPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.55),
          AppColors.primaryDeep,
        ],
      ).createShader(poolRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(poolRect, const Radius.circular(18)),
      poolPaint,
    );

    for (var i = 0; i < 6; i++) {
      final y = poolRect.top + 8 + (i * 7);
      canvas.drawLine(
        Offset(12, y),
        Offset(size.width - 12, y + 3),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 2,
      );
    }

    final ropeX = size.width * 0.18;
    final ropeTop = size.height * 0.08;
    final ropeBottom = poolRect.top + 8;

    final ropeColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFEAB308),
      const Color(0xFF22C55E),
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
    ];

    final segmentHeight = (ropeBottom - ropeTop) / ropeColors.length;
    for (var i = 0; i < ropeColors.length; i++) {
      canvas.drawLine(
        Offset(ropeX, ropeTop + segmentHeight * i),
        Offset(ropeX, ropeTop + segmentHeight * (i + 1)),
        Paint()
          ..color = ropeColors[i]
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    final progressY = ropeBottom - ((ropeBottom - ropeTop) * climbFraction);
    canvas.drawCircle(
      Offset(ropeX, progressY),
      8,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RopeClimbPainter oldDelegate) =>
      oldDelegate.climbFraction != climbFraction;
}
