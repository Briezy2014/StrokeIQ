import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Branding asset paths.
abstract final class SwimIqBranding {
  /// Square icon only — safe for app bar, tab headers, dashboard hero.
  static const iconOnlyCandidates = [
    'assets/branding/swimiq_icon.png',
    'assets/branding/swimiq_icon_mark.png',
    'assets/branding/icon_mark.png',
    'assets/branding/icon.png',
  ];

  /// Tight crop: triangle/swimmer mark only (best for app bar & tab headers).
  static const iconMarkCandidates = [
    ...iconOnlyCandidates,
  ];

  /// Full square lockup (icon + wordmark + tagline on black) — for login/splash.
  static const fullLockupCandidates = [
    'assets/branding/swimiq_icon.png',
    'assets/branding/swimiq_hero.png',
    'assets/images/swimiq_logo.png',
    'assets/branding/swimiq_logo.png',
    'assets/branding/swimiq_logo_square.png',
    'assets/branding/icon.png',
  ];

  /// Small slots: icon first; huge lockup PNG only as last resort (no zoom).
  static const compactCandidates = [
    ...iconOnlyCandidates,
  ];

  static const heroCandidates = [
    'assets/branding/swimiq_hero.png',
    'assets/branding/swimiq_icon.png',
    'assets/images/swimiq_logo.png',
    'assets/branding/hero.png',
    'assets/branding/banner.png',
    'assets/branding/swimiq_banner.png',
    'assets/branding/swimiq_logo_full.png',
    'assets/branding/swimiq_logo.png',
  ];

  static const iconCandidates = [
    'assets/branding/swimiq_icon.png',
    'assets/images/swimiq_logo.png',
    'assets/branding/icon.png',
    'assets/branding/logo_icon.png',
    'assets/branding/swimiq_logo_icon.png',
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
    final w = widget.width;
    final h = widget.height;

    if (!_resolved) {
      return SizedBox(width: w, height: h);
    }

    if (_resolvedPath == null) {
      return widget.fallback ??
          Icon(
            Icons.pool,
            size: (h ?? w ?? 48) * 0.7,
            color: Colors.white,
          );
    }

    Widget image = Image.asset(
      _resolvedPath!,
      width: w,
      height: h,
      fit: widget.fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    if (w != null && h != null) {
      image = SizedBox(
        width: w,
        height: h,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: image,
        ),
      );
    }

    if (widget.borderRadius <= 0) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      clipBehavior: Clip.hardEdge,
      child: image,
    );
  }
}
