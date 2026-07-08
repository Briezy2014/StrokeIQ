import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Branding asset paths.
abstract final class SwimIqBranding {
  /// Tight crop: triangle/swimmer mark only (best for app bar & tab headers).
  static const iconMarkCandidates = [
    'assets/branding/swimiq_icon_mark.png',
    'assets/branding/icon_mark.png',
  ];

  /// Full square lockup — swimiq_logo.png first (Kara's file; avoids stale swimiq_icon.png).
  static const fullLockupCandidates = [
    'assets/branding/swimiq_logo.png',
    'assets/branding/swimiq_icon.png',
    'assets/branding/swimiq_logo_square.png',
    'assets/branding/icon.png',
  ];

  /// Small slots: logo first, then mark-only crop, then legacy icon name.
  static const compactCandidates = [
    'assets/branding/swimiq_logo.png',
    'assets/branding/swimiq_icon_mark.png',
    'assets/branding/icon_mark.png',
    'assets/branding/swimiq_icon.png',
    'assets/branding/swimiq_logo_square.png',
    'assets/branding/icon.png',
  ];

  /// Crops swimmer mark from a full lockup PNG (hides wordmark/tagline text).
  static const compactZoomScale = 5.0;
  static const compactZoomAlignment = Alignment(0, -0.92);
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
    this.zoomToMark = false,
  });

  final List<String> candidates;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? fallback;
  /// When true, zooms into the top of a full lockup so the swimmer mark fills the slot.
  final bool zoomToMark;

  @override
  State<SwimIqBrandedImage> createState() => _SwimIqBrandedImageState();
}

class _SwimIqBrandedImageState extends State<SwimIqBrandedImage> {
  String? _resolvedPath;
  bool _resolved = false;

  bool get _isMarkOnly =>
      _resolvedPath != null &&
      SwimIqBranding.iconMarkCandidates.contains(_resolvedPath);

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
      errorBuilder: (_, __, ___) => widget.fallback ?? const SizedBox.shrink(),
    );

    final shouldZoom = widget.zoomToMark && !_isMarkOnly;
    if (shouldZoom && w != null && h != null) {
      image = ClipRect(
        child: SizedBox(
          width: w,
          height: h,
          child: Transform.scale(
            scale: SwimIqBranding.compactZoomScale,
            alignment: SwimIqBranding.compactZoomAlignment,
            child: Image.asset(
              _resolvedPath!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        ),
      );
    }

    if (widget.borderRadius <= 0) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: image,
    );
  }
}
