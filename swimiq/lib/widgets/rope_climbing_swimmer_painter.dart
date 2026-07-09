import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Side-view swimmer climbing the rope — always used on the Daily Rope Climb card.
class RopeClimbingSwimmerPainter extends CustomPainter {
  const RopeClimbingSwimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final ropeX = w * 0.62;

    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7DD3FC),
            AppColors.primary,
            AppColors.primaryDeep,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.48)),
    );

    _drawRope(canvas, ropeX, h, w);

    final skin = const Color(0xFFFFE4C9);
    final suit = AppColors.primaryDeep;
    final cap = const Color(0xFF0EA5E9);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headCenter = Offset(ropeX - w * 0.2, h * 0.24);

    canvas.drawCircle(headCenter, w * 0.11, Paint()..color = skin);
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: w * 0.11),
      math.pi * 0.95,
      math.pi * 0.95,
      false,
      Paint()
        ..color = cap
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055,
    );
    canvas.drawCircle(
      headCenter.translate(0, w * 0.01),
      w * 0.115,
      Paint()
        ..color = cap.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03,
    );

    canvas.drawLine(
      headCenter.translate(-w * 0.05, w * 0.02),
      headCenter.translate(w * 0.05, w * 0.02),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round,
    );

    final torso = Path()
      ..moveTo(headCenter.dx, headCenter.dy + w * 0.1)
      ..quadraticBezierTo(
        ropeX - w * 0.36,
        h * 0.42,
        ropeX - w * 0.14,
        h * 0.56,
      )
      ..quadraticBezierTo(
        ropeX - w * 0.06,
        h * 0.68,
        ropeX - w * 0.16,
        h * 0.8,
      );
    canvas.drawPath(
      torso,
      Paint()
        ..color = suit
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.13
        ..strokeCap = StrokeCap.round,
    );

    final reachArm = Path()
      ..moveTo(ropeX - w * 0.14, h * 0.38)
      ..quadraticBezierTo(ropeX + w * 0.02, h * 0.3, ropeX + w * 0.08, h * 0.18);
    canvas.drawPath(reachArm, stroke);

    final gripArm = Path()
      ..moveTo(ropeX - w * 0.1, h * 0.5)
      ..quadraticBezierTo(ropeX + w * 0.1, h * 0.5, ropeX + w * 0.12, h * 0.64);
    canvas.drawPath(gripArm, stroke);

    canvas.drawCircle(
      Offset(ropeX + w * 0.08, h * 0.18),
      w * 0.035,
      Paint()..color = skin,
    );
    canvas.drawCircle(
      Offset(ropeX + w * 0.12, h * 0.64),
      w * 0.035,
      Paint()..color = skin,
    );

    final upperLeg = Path()
      ..moveTo(ropeX - w * 0.16, h * 0.8)
      ..quadraticBezierTo(ropeX - w * 0.34, h * 0.86, ropeX - w * 0.3, h * 0.94);
    final lowerLeg = Path()
      ..moveTo(ropeX - w * 0.3, h * 0.94)
      ..quadraticBezierTo(ropeX - w * 0.22, h * 0.9, ropeX - w * 0.12, h * 0.88);
    canvas.drawPath(upperLeg, stroke);
    canvas.drawPath(lowerLeg, stroke);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ropeX - w * 0.3, h * 0.945),
        width: w * 0.12,
        height: w * 0.05,
      ),
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.85),
    );

    canvas.drawCircle(
      Offset(ropeX - w * 0.12, h * 0.88),
      w * 0.03,
      Paint()..color = skin,
    );
  }

  void _drawRope(Canvas canvas, double ropeX, double h, double w) {
    final ropePaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ropeX, h * 0.05), Offset(ropeX, h * 0.95), ropePaint);
    canvas.drawLine(
      Offset(ropeX - w * 0.022, h * 0.05),
      Offset(ropeX - w * 0.022, h * 0.95),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant RopeClimbingSwimmerPainter oldDelegate) => false;
}
