import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Waist-up climber on the scene rope — no extra rope or splayed legs (reads as a person, not a squid).
class RopeClimbingSwimmerPainter extends CustomPainter {
  const RopeClimbingSwimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ropeX = w * 0.38;

    final pin = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.04, w * 0.88, h * 0.88),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(
      pin,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      pin,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final skin = const Color(0xFFFFE0C2);
    final suit = AppColors.primaryDeep;
    final cap = AppColors.primary;

    final headCenter = Offset(w * 0.56, h * 0.28);
    final headR = w * 0.13;
    canvas.drawCircle(headCenter, headR, Paint()..color = skin);
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headR),
      math.pi * 1.05,
      math.pi * 1.1,
      true,
      Paint()..color = cap,
    );
    canvas.drawCircle(
      Offset(headCenter.dx - headR * 0.35, headCenter.dy + headR * 0.05),
      w * 0.022,
      Paint()..color = const Color(0xFF0EA5E9),
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.52),
        width: w * 0.3,
        height: h * 0.28,
      ),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(torso, Paint()..color = suit);

    final armStroke = Paint()
      ..color = suit
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.48, h * 0.4),
      Offset(ropeX, h * 0.18),
      armStroke,
    );
    canvas.drawLine(
      Offset(w * 0.46, h * 0.46),
      Offset(ropeX, h * 0.34),
      armStroke,
    );

    canvas.drawCircle(
      Offset(ropeX, h * 0.18),
      w * 0.045,
      Paint()..color = skin,
    );
    canvas.drawCircle(
      Offset(ropeX, h * 0.34),
      w * 0.04,
      Paint()..color = skin,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.66),
        width: w * 0.22,
        height: h * 0.12,
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = suit
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant RopeClimbingSwimmerPainter oldDelegate) => false;
}
