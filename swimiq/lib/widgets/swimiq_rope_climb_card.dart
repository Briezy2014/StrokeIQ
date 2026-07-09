import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/gamification/swimiq_badges.dart';
import '../core/gamification/swimiq_daily_progress.dart';
import '../core/theme/app_theme.dart';
import 'rope_climbing_swimmer_painter.dart';

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
                Icon(Icons.trending_up, color: AppColors.primaryDeep, size: 26),
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
                _ScorePill(
                  label: 'Score',
                  value: '${daily.overallSwimIqScore}/${SwimIqDailyProgress.ropeScoreMax}',
                ),
                const SizedBox(width: 6),
                _ScorePill(
                  label: 'Today\'s log',
                  value: '${daily.todayPoints}/100',
                  muted: daily.todayPoints == 0,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _ropeClimbExplanation(daily),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: _RopeClimbScene(
                climbFraction: daily.ropeClimbFraction,
                swimIqScore: daily.overallSwimIqScore,
                climbPercent: daily.ropeClimbPercent,
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

String _ropeClimbExplanation(SwimIqDailyProgress daily) {
  final scorePercent = (daily.scoreRopePercent * 100).round();
  final boost = daily.todayPoints;
  if (boost > 0) {
    return 'Your SwimIQ score (${daily.overallSwimIqScore} out of '
        '${SwimIqDailyProgress.ropeScoreMax}) sets your rope height at $scorePercent%. '
        'Today\'s log adds +$boost boost pts on top (max 100 per day).';
  }
  return 'Your SwimIQ score (${daily.overallSwimIqScore} out of '
      '${SwimIqDailyProgress.ropeScoreMax}) sets your rope height at $scorePercent%. '
      'Log a practice, meet, or video today to earn up to 100 daily boost points.';
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: muted
              ? [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                ]
              : [
                  AppColors.accent.withValues(alpha: 0.35),
                  AppColors.primary.withValues(alpha: 0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: muted
              ? Colors.grey.shade300
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: muted ? Colors.grey.shade600 : AppColors.primaryDeep,
                  fontSize: 9,
                  letterSpacing: 0.2,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: muted ? Colors.grey.shade700 : AppColors.primaryDark,
                ),
          ),
        ],
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
  const _RopeClimbScene({
    required this.climbFraction,
    required this.swimIqScore,
    required this.climbPercent,
  });

  final double climbFraction;
  final int swimIqScore;
  final int climbPercent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final poolTop = height * 0.72;
        final ropeTop = height * 0.06;
        final ropeBottom = poolTop + 8;
        final ropeX = width * 0.2;
        final progressY =
            ropeBottom - ((ropeBottom - ropeTop) * climbFraction);
        const markerWidth = 54.0;
        const markerHeight = 54.0;
        const labelHeight = 24.0;
        const labelGap = 4.0;
        final markerHeightTotal = markerHeight + labelGap + labelHeight;
        final top =
            (progressY - markerHeight / 2).clamp(0.0, height - markerHeightTotal);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _RopeClimbPainter(climbFraction: climbFraction),
            ),
            Positioned(
              left: ropeX - (markerWidth / 2),
              top: top,
              child: _RopeSwimmerMarker(
                width: markerWidth,
                height: markerHeight,
                swimIqScore: swimIqScore,
                climbPercent: climbPercent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RopeSwimmerMarker extends StatelessWidget {
  const _RopeSwimmerMarker({
    required this.width,
    required this.height,
    required this.swimIqScore,
    required this.climbPercent,
  });

  final double width;
  final double height;
  final int swimIqScore;
  final int climbPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: const RopeClimbingSwimmerPainter(),
          size: Size(width, height),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            swimIqScore > 0
                ? '$swimIqScore/${SwimIqDailyProgress.ropeScoreMax} · $climbPercent%'
                : '$climbPercent% up',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeep,
              letterSpacing: 0.2,
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

  static const _ropeColors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.72);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFBAE6FD),
            const Color(0xFFE0F2FE),
            Colors.white.withValues(alpha: 0.4),
          ],
        ).createShader(skyRect),
    );

    final poolRect =
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28);
    final poolPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.65),
          AppColors.primaryDeep,
          const Color(0xFF0C4A6E),
        ],
      ).createShader(poolRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(poolRect, const Radius.circular(18)),
      poolPaint,
    );

    for (var i = 0; i < 7; i++) {
      final y = poolRect.top + 6 + (i * 8);
      canvas.drawLine(
        Offset(12, y),
        Offset(size.width - 12, y + 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..strokeWidth = 2,
      );
    }

    final ropeX = size.width * 0.2;
    final ropeTop = size.height * 0.06;
    final ropeBottom = poolRect.top + 8;

    _drawPulley(canvas, Offset(ropeX, ropeTop - 4));

    final ropeHeight = ropeBottom - ropeTop;
    final segmentHeight = ropeHeight / _ropeColors.length;

    for (var i = 0; i < _ropeColors.length; i++) {
      final segTop = ropeTop + segmentHeight * i;
      final segBottom = ropeTop + segmentHeight * (i + 1);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _ropeColors[i].withValues(alpha: 0.85),
            _ropeColors[i],
            _ropeColors[i].withValues(alpha: 0.75),
          ],
        ).createShader(Rect.fromLTWH(ropeX - 8, segTop, 16, segmentHeight))
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(ropeX, segTop), Offset(ropeX, segBottom), paint);

      for (var knot = 0; knot < 3; knot++) {
        final ky = segTop + (segmentHeight * (knot + 1) / 4);
        canvas.drawCircle(
          Offset(ropeX, ky),
          2.5,
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
      }
    }

    canvas.drawLine(
      Offset(ropeX - 5, ropeTop),
      Offset(ropeX - 5, ropeBottom),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    final progressY = ropeBottom - (ropeHeight * climbFraction);
    _drawSparkles(canvas, Offset(ropeX, progressY));

    canvas.drawCircle(
      Offset(ropeX, progressY),
      10,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            AppColors.accent.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromCircle(center: Offset(ropeX, progressY), radius: 10)),
    );
    canvas.drawCircle(
      Offset(ropeX, progressY),
      10,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final climbedHeight = ropeBottom - progressY;
    if (climbedHeight > 4) {
      canvas.drawLine(
        Offset(ropeX + 6, progressY),
        Offset(ropeX + 6, ropeBottom),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawPulley(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE08A),
            const Color(0xFFD97706),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 14)),
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = const Color(0xFF78350F),
    );
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawSparkles(Canvas canvas, Offset center) {
    for (var i = 0; i < 5; i++) {
      final angle = i * 1.2;
      final radius = 16 + (i * 3);
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius * 0.6;
      canvas.drawCircle(
        Offset(x, y),
        2 + (i % 2),
        Paint()..color = Colors.white.withValues(alpha: 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RopeClimbPainter oldDelegate) =>
      oldDelegate.climbFraction != climbFraction;
}
