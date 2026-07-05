import 'package:flutter/material.dart';

/// Branded SwimIQ™ logo asset used across gate, app bar, and passport hero.
class SwimIqLogo extends StatelessWidget {
  const SwimIqLogo({
    super.key,
    this.size = 72,
    this.borderRadius = 16,
  });

  final double size;
  final double borderRadius;

  static const assetPath = 'assets/branding/swimiq_logo.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.pool, size: size * 0.7, color: Colors.white);
        },
      ),
    );
  }
}

class SwimIqWordmark extends StatelessWidget {
  const SwimIqWordmark({
    super.key,
    this.fontSize = 22,
    this.showTm = true,
  });

  final double fontSize;
  final bool showTm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            children: const [
              TextSpan(text: 'SWIM', style: TextStyle(color: Colors.white)),
              TextSpan(
                text: 'IQ',
                style: TextStyle(color: Color(0xFF009CFF)),
              ),
            ],
          ),
        ),
        if (showTm)
          const Padding(
            padding: EdgeInsets.only(top: 2, left: 2),
            child: Text(
              '™',
              style: TextStyle(
                color: Color(0xFF009CFF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
