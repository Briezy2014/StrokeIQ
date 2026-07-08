import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Built-in SwimIQ branding when PNG assets are not bundled yet.
class SwimIqBrandedFallback extends StatelessWidget {
  const SwimIqBrandedFallback({
    super.key,
    required this.variant,
    this.width,
    this.height,
    this.borderRadius = 16,
  });

  final SwimIqBrandedVariant variant;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050505),
              Color(0xFF0B2D4D),
              Color(0xFF0077C8),
            ],
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: variant == SwimIqBrandedVariant.hero ? 18 : 10,
          vertical: variant == SwimIqBrandedVariant.hero ? 14 : 8,
        ),
        child: variant == SwimIqBrandedVariant.icon
            ? Center(child: _Mark(size: (height ?? width ?? 48) * 0.72))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Mark(size: (height ?? 72) * 0.42),
                  const SizedBox(height: 8),
                  const _Wordmark(fontSize: 22),
                  if (AppConstants.tagline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.tagline,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

enum SwimIqBrandedVariant { icon, hero }

class _Mark extends StatelessWidget {
  const _Mark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwimMarkPainter(),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          height: 1,
        ),
        children: const [
          TextSpan(text: 'SWIM', style: TextStyle(color: Colors.white)),
          TextSpan(
            text: 'IQ',
            style: TextStyle(color: AppColors.primary),
          ),
          TextSpan(
            text: '™',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwimMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final triangle = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.96, h * 0.92)
      ..lineTo(w * 0.04, h * 0.92)
      ..close();

    final trianglePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary, AppColors.primaryDeep],
      ).createShader(Offset.zero & size);
    canvas.drawPath(triangle, trianglePaint);

    final swimmer = Path()
      ..moveTo(w * 0.22, h * 0.58)
      ..quadraticBezierTo(w * 0.42, h * 0.42, w * 0.62, h * 0.5)
      ..quadraticBezierTo(w * 0.78, h * 0.56, w * 0.88, h * 0.48);

    final swimmerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(swimmer, swimmerPaint);

    canvas.drawCircle(
      Offset(w * 0.24, h * 0.52),
      w * 0.055,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
