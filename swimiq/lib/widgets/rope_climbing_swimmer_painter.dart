import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Small marker: swimmer climbing up the rope (vertical pose reads at a glance).
class RopeClimbingSwimmerPainter extends CustomPainter {
  const RopeClimbingSwimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final ropeX = cx;

    canvas.drawCircle(
      Offset(cx, h * 0.5),
      w * 0.46,
      Paint()..color = Colors.white.withValues(alpha: 0.96),
    );
    canvas.drawCircle(
      Offset(cx, h * 0.5),
      w * 0.46,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final ropePaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(ropeX, h * 0.1),
      Offset(ropeX, h * 0.9),
      ropePaint,
    );
    for (var i = 0; i < 4; i++) {
      final ky = h * (0.24 + i * 0.16);
      canvas.drawCircle(
        Offset(ropeX, ky),
        w * 0.028,
        Paint()..color = const Color(0xFFD97706).withValues(alpha: 0.8),
      );
    }

    final skin = const Color(0xFFFFE0C2);
    final suit = AppColors.primaryDeep;
    final cap = AppColors.primary;
    final limb = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.052
      ..strokeCap = StrokeCap.round;

    final head = Offset(cx, h * 0.24);
    canvas.drawCircle(head, w * 0.11, Paint()..color = skin);
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: w * 0.11),
      math.pi * 1.05,
      math.pi * 1.35,
      false,
      Paint()
        ..color = cap
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.075,
    );
    canvas.drawCircle(
      Offset(head.dx - w * 0.04, head.dy + w * 0.01),
      w * 0.02,
      Paint()..color = const Color(0xFF0EA5E9),
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.46),
        width: w * 0.24,
        height: h * 0.28,
      ),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(torso, Paint()..color = suit);

    final reachArm = Path()
      ..moveTo(cx + w * 0.04, h * 0.34)
      ..quadraticBezierTo(cx + w * 0.14, h * 0.16, ropeX, h * 0.14);
    canvas.drawPath(reachArm, limb);
    canvas.drawCircle(
      Offset(ropeX, h * 0.14),
      w * 0.034,
      Paint()..color = skin,
    );

    final gripArm = Path()
      ..moveTo(cx - w * 0.04, h * 0.38)
      ..quadraticBezierTo(cx - w * 0.1, h * 0.28, ropeX, h * 0.3);
    canvas.drawPath(gripArm, limb..strokeWidth = w * 0.046);
    canvas.drawCircle(
      Offset(ropeX, h * 0.3),
      w * 0.03,
      Paint()..color = skin,
    );

    final leftLeg = Path()
      ..moveTo(cx - w * 0.03, h * 0.58)
      ..quadraticBezierTo(cx - w * 0.16, h * 0.72, cx - w * 0.08, h * 0.82);
    final rightLeg = Path()
      ..moveTo(cx + w * 0.03, h * 0.58)
      ..quadraticBezierTo(cx + w * 0.14, h * 0.7, cx + w * 0.1, h * 0.84);
    canvas.drawPath(leftLeg, limb..strokeWidth = w * 0.044);
    canvas.drawPath(rightLeg, limb);

    canvas.drawCircle(
      Offset(cx - w * 0.08, h * 0.82),
      w * 0.028,
      Paint()..color = skin,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.1, h * 0.84),
      w * 0.028,
      Paint()..color = skin,
    );
  }

  @override
  bool shouldRepaint(covariant RopeClimbingSwimmerPainter oldDelegate) => false;
}
