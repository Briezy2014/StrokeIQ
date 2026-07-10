import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Compact climber beside the rope — transparent, no white box over the rainbow rope.
class RopeClimbingSwimmerPainter extends CustomPainter {
  const RopeClimbingSwimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skin = const Color(0xFFFFE0C2);
    final suit = AppColors.primaryDeep;
    final cap = AppColors.primary;
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final head = Offset(w * 0.68, h * 0.3);
    final headR = w * 0.16;
    canvas.drawCircle(head, headR + 1.2, outline);
    canvas.drawCircle(head, headR, Paint()..color = skin);
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: headR),
      math.pi * 1.0,
      math.pi * 1.2,
      true,
      Paint()..color = cap,
    );
    canvas.drawCircle(
      Offset(head.dx - headR * 0.3, head.dy + headR * 0.05),
      w * 0.028,
      Paint()..color = const Color(0xFF0EA5E9),
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.58),
        width: w * 0.34,
        height: h * 0.3,
      ),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(torso, Paint()..color = suit);

    final arm = Paint()
      ..color = suit
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    final gripX = w * 0.18;
    canvas.drawLine(Offset(w * 0.52, h * 0.42), Offset(gripX, h * 0.24), arm);
    canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(gripX, h * 0.4), arm);
    canvas.drawCircle(Offset(gripX, h * 0.24), w * 0.05, Paint()..color = skin);
    canvas.drawCircle(Offset(gripX, h * 0.4), w * 0.045, Paint()..color = skin);
  }

  @override
  bool shouldRepaint(covariant RopeClimbingSwimmerPainter oldDelegate) => false;
}
