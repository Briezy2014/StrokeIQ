import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Known branding asset filenames (first match wins).
abstract final class SwimIqBranding {
  static const iconCandidates = [
    'assets/branding/swimiq_icon.png',
    'assets/images/swimiq_logo.png',
    'assets/branding/icon.png',
    'assets/branding/logo_icon.png',
    'assets/branding/swimiq_logo_icon.png',
    'assets/branding/swimiq_logo.png',
  ];

  static const heroCandidates = [
    'assets/branding/swimiq_hero.png',
    'assets/images/swimiq_logo.png',
    'assets/branding/hero.png',
    'assets/branding/banner.png',
    'assets/branding/swimiq_banner.png',
    'assets/branding/swimiq_logo_full.png',
    'assets/branding/swimiq_logo.png',
  ];
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
  String? _resolvedPath;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolveAsset();
  }

  Future<void> _resolveAsset() async {
    for (final path in widget.candidates) {
      try {
        await rootBundle.load(path);
        if (!mounted) return;
        setState(() {
          _resolvedPath = path;
          _resolved = true;
        });
        return;
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      _resolvedPath = null;
      _resolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    if (_resolvedPath == null) {
      return widget.fallback ??
          Icon(
            Icons.pool,
            size: (widget.height ?? widget.width ?? 48) * 0.7,
            color: Colors.white,
          );
    }

    final image = Image.asset(
      _resolvedPath!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
    );

    if (widget.borderRadius <= 0) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: image,
    );
  }
}
