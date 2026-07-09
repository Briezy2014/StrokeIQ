import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Compact side-view swimmer gripping the rope — no background bubble.
class RopeClimbingSwimmerPainter extends CustomPainter {
  const RopeClimbingSwimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ropeX = w * 0.58;

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ropeX - w * 0.08, h * 0.72),
        width: w * 0.55,
        height: h * 0.1,
      ),
      shadow,
    );

    _drawRope(canvas, ropeX, h, w);

    final skin = const Color(0xFFFFE4C9);
    final suit = AppColors.primaryDeep;
    final cap = AppColors.primary;
    final limb = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final head = Offset(ropeX - w * 0.22, h * 0.2);

    canvas.drawCircle(head, w * 0.13, Paint()..color = skin);
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: w * 0.13),
      math.pi * 0.85,
      math.pi * 1.1,
      false,
      Paint()
        ..color = cap
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07,
    );
    canvas.drawCircle(
      head.translate(0, w * 0.015),
      w * 0.135,
      Paint()
        ..color = cap.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );
    canvas.drawCircle(
      head.translate(w * 0.04, w * 0.02),
      w * 0.018,
      Paint()..color = const Color(0xFF1E293B),
    );

    final torso = Path()
      ..moveTo(head.dx, head.dy + w * 0.12)
      ..quadraticBezierTo(
        ropeX - w * 0.42,
        h * 0.4,
        ropeX - w * 0.18,
        h * 0.52,
      )
      ..quadraticBezierTo(
        ropeX - w * 0.1,
        h * 0.66,
        ropeX - w * 0.22,
        h * 0.78,
      );
    canvas.drawPath(
      torso,
      Paint()
        ..color = suit
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.16
        ..strokeCap = StrokeCap.round,
    );

    final reachArm = Path()
      ..moveTo(ropeX - w * 0.18, h * 0.34)
      ..quadraticBezierTo(ropeX + w * 0.02, h * 0.26, ropeX + w * 0.06, h * 0.12);
    final gripArm = Path()
      ..moveTo(ropeX - w * 0.14, h * 0.46)
      ..quadraticBezierTo(ropeX + w * 0.12, h * 0.46, ropeX + w * 0.14, h * 0.58);
    canvas.drawPath(reachArm, limb);
    canvas.drawPath(gripArm, limb);

    canvas.drawCircle(
      Offset(ropeX + w * 0.06, h * 0.12),
      w * 0.04,
      Paint()..color = skin,
    );
    canvas.drawCircle(
      Offset(ropeX + w * 0.14, h * 0.58),
      w * 0.04,
      Paint()..color = skin,
    );

    final upperLeg = Path()
      ..moveTo(ropeX - w * 0.22, h * 0.78)
      ..quadraticBezierTo(ropeX - w * 0.38, h * 0.84, ropeX - w * 0.34, h * 0.93);
    final lowerLeg = Path()
      ..moveTo(ropeX - w * 0.34, h * 0.93)
      ..quadraticBezierTo(ropeX - w * 0.24, h * 0.88, ropeX - w * 0.14, h * 0.86);
    canvas.drawPath(upperLeg, limb);
    canvas.drawPath(lowerLeg, limb);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ropeX - w * 0.34, h * 0.945),
        width: w * 0.14,
        height: w * 0.06,
      ),
      Paint()..color = AppColors.primary.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(ropeX - w * 0.14, h * 0.86),
      w * 0.035,
      Paint()..color = skin,
    );
  }

  void _drawRope(Canvas canvas, double ropeX, double h, double w) {
    canvas.drawLine(
      Offset(ropeX, h * 0.04),
      Offset(ropeX, h * 0.96),
      Paint()
        ..color = const Color(0xFF92400E)
        ..strokeWidth = w * 0.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(ropeX - w * 0.025, h * 0.04),
      Offset(ropeX - w * 0.025, h * 0.96),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant RopeClimbingSwimmerPainter oldDelegate) => false;
}
