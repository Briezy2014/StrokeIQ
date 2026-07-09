import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Side-view freestyle swimmer — clear at small sizes on the rope marker.
class RopeClimbingSwimmerPainter extends CustomPainter {
  const RopeClimbingSwimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.47,
      Paint()..color = AppColors.primary.withValues(alpha: 0.1),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.47,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final skin = const Color(0xFFFFE0C2);
    final suit = AppColors.primaryDeep;
    final cap = AppColors.primary;
    final limb = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;

    final head = Offset(w * 0.2, h * 0.4);
    canvas.drawCircle(head, w * 0.12, Paint()..color = skin);
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: w * 0.12),
      -math.pi * 0.3,
      math.pi * 1.15,
      false,
      Paint()
        ..color = cap
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07,
    );
    canvas.drawCircle(
      Offset(head.dx + w * 0.05, head.dy + w * 0.01),
      w * 0.024,
      Paint()..color = const Color(0xFF0EA5E9),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.5),
        width: w * 0.44,
        height: w * 0.19,
      ),
      Paint()..color = suit,
    );

    final leadArm = Path()
      ..moveTo(w * 0.6, h * 0.45)
      ..quadraticBezierTo(w * 0.8, h * 0.3, w * 0.9, h * 0.36);
    canvas.drawPath(leadArm, limb);
    canvas.drawCircle(
      Offset(w * 0.9, h * 0.36),
      w * 0.038,
      Paint()..color = skin,
    );

    final trailArm = Path()
      ..moveTo(w * 0.4, h * 0.52)
      ..quadraticBezierTo(w * 0.28, h * 0.64, w * 0.2, h * 0.56);
    canvas.drawPath(trailArm, limb..strokeWidth = w * 0.048);
    canvas.drawCircle(
      Offset(w * 0.2, h * 0.56),
      w * 0.032,
      Paint()..color = skin,
    );

    final kick = Path()
      ..moveTo(w * 0.64, h * 0.54)
      ..quadraticBezierTo(w * 0.82, h * 0.44, w * 0.9, h * 0.5)
      ..moveTo(w * 0.64, h * 0.56)
      ..quadraticBezierTo(w * 0.84, h * 0.6, w * 0.92, h * 0.54);
    canvas.drawPath(kick, limb..strokeWidth = w * 0.042);

    canvas.drawCircle(
      Offset(w * 0.1, h * 0.26),
      2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      Offset(w * 0.06, h * 0.34),
      1.6,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant RopeClimbingSwimmerPainter oldDelegate) => false;
}
