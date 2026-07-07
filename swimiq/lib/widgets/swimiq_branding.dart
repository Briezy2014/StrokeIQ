import 'package:flutter/material.dart';

/// Single SwimIQ logo used across the entire app (splash, login, app bar, passport).
abstract final class SwimIqBranding {
  static const logoCandidates = [
    'assets/branding/swimiq_logo.png',
    'assets/images/swimiq_logo.png',
  ];

  @Deprecated('Use logoCandidates — one logo file for the whole app.')
  static const iconCandidates = logoCandidates;

  @Deprecated('Use logoCandidates — one logo file for the whole app.')
  static const heroCandidates = logoCandidates;
}

/// Loads the first existing asset from [candidates], then [fallback].
class SwimIqBrandedImage extends StatefulWidget {
  const SwimIqBrandedImage({
    super.key,
    required this.candidates,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 0,
    this.fallback,
  });

  final List<String> candidates;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? fallback;

  @override
  State<SwimIqBrandedImage> createState() => _SwimIqBrandedImageState();
}

class _SwimIqBrandedImageState extends State<SwimIqBrandedImage> {
  int _candidateIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_candidateIndex >= widget.candidates.length) {
      return widget.fallback ??
          Icon(
            Icons.pool,
            size: (widget.height ?? widget.width ?? 48) * 0.7,
            color: Colors.white,
          );
    }

    final path = widget.candidates[_candidateIndex];
    final image = Image.asset(
      path,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_candidateIndex + 1 < widget.candidates.length) {
            setState(() => _candidateIndex++);
          }
        });
        return const SizedBox.shrink();
      },
    );

    if (widget.borderRadius <= 0) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: image,
    );
  }
}
