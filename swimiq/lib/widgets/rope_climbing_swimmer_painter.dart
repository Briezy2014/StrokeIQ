import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Side-view swimmer gripping the rope — fallback when mark/icon PNG is missing.
class RopeClimbingSwimmerPainter extends CustomPainter {
  const RopeClimbingSwimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ropeX = w * 0.56;

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.47,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFF38BDF8),
            AppColors.primary,
            AppColors.primaryDeep,
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.47)),
    );

    final ropePaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ropeX, h * 0.04), Offset(ropeX, h * 0.96), ropePaint);

    canvas.drawLine(
      Offset(ropeX - w * 0.025, h * 0.04),
      Offset(ropeX - w * 0.025, h * 0.96),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round,
    );

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headCenter = Offset(ropeX - w * 0.17, h * 0.26);
    canvas.drawCircle(headCenter, w * 0.1, Paint()..color = Colors.white);
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: w * 0.1),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045,
    );

    final torso = Path()
      ..moveTo(headCenter.dx, headCenter.dy + w * 0.08)
      ..quadraticBezierTo(
        ropeX - w * 0.34,
        h * 0.46,
        ropeX - w * 0.1,
        h * 0.58,
      )
      ..quadraticBezierTo(
        ropeX - w * 0.02,
        h * 0.68,
        ropeX - w * 0.12,
        h * 0.78,
      );
    canvas.drawPath(torso, stroke);

    final upperArm = Path()
      ..moveTo(ropeX - w * 0.12, h * 0.4)
      ..quadraticBezierTo(ropeX + w * 0.02, h * 0.34, ropeX + w * 0.06, h * 0.22);
    canvas.drawPath(upperArm, stroke);

    final gripArm = Path()
      ..moveTo(ropeX - w * 0.08, h * 0.5)
      ..quadraticBezierTo(ropeX + w * 0.08, h * 0.52, ropeX + w * 0.1, h * 0.66);
    canvas.drawPath(gripArm, stroke);

    final kick = Path()
      ..moveTo(ropeX - w * 0.12, h * 0.78)
      ..quadraticBezierTo(ropeX - w * 0.34, h * 0.86, ropeX - w * 0.28, h * 0.94)
      ..moveTo(ropeX - w * 0.1, h * 0.8)
      ..quadraticBezierTo(ropeX - w * 0.02, h * 0.9, ropeX + w * 0.06, h * 0.88);
    canvas.drawPath(kick, stroke);
  }

  @override
  bool shouldRepaint(covariant RopeClimbingSwimmerPainter oldDelegate) => false;
}
