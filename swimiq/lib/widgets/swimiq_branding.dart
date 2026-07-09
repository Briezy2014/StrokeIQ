import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// Branding asset paths — login uses [loginIconCandidates] (square icon only).
abstract final class SwimIqBranding {
  static const iconAsset = 'assets/branding/icon.png';
  static const bannerAsset = 'assets/branding/banner.png';
  static const markAsset = 'assets/branding/mark.png';

  /// Login, splash, signup — square app icon only ([iconAsset]).
  static const loginIconCandidates = [iconAsset];

  /// Tight swimmer mark only (app bar, tab banner beside wordmark).
  static const markCandidates = [
    markAsset,
    'assets/branding/SwimIQ_Mark.PNG',
    'assets/branding/SwimIQ_Mark.png',
    'assets/branding/swimiq_icon_mark.png',
    'assets/branding/icon_mark.png',
  ];

  @Deprecated('Use markCandidates')
  static const iconMarkCandidates = markCandidates;

  /// Wide tab-header banner.
  static const tabBannerCandidates = [
    bannerAsset,
    'assets/branding/SwimIQ_banner.PNG',
    'assets/branding/SwimIQ_banner.png',
    'assets/branding/swimiq_banner.png',
    'assets/branding/swimiq_banner.PNG',
  ];

  /// Full square lockup when a wide hero slot needs the icon file.
  static const fullLockupCandidates = loginIconCandidates;

  /// Small slots: dedicated mark first, then square icon.
  static const compactCandidates = [
    markAsset,
    'assets/branding/SwimIQ_Mark.PNG',
    'assets/branding/swimiq_icon_mark.png',
    'assets/branding/icon_mark.png',
    iconAsset,
    'assets/branding/swimiq_icon.png',
    'assets/branding/swimiq_logo.png',
    'assets/branding/swimiq_logo_square.png',
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
    this.alignment = Alignment.center,
    this.borderRadius = 0,
    this.fallback,
    this.zoomToMark = false,
  });

  final List<String> candidates;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
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
      SwimIqBranding.markCandidates.contains(_resolvedPath);

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

    final isFullLockup = _resolvedPath != null &&
        SwimIqBranding.fullLockupCandidates.contains(_resolvedPath);

    if (!_resolved) {
      return widget.fallback ??
          SizedBox(
            width: w,
            height: h,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
    }

    if (_resolvedPath == null) {
      return widget.fallback ??
          Icon(
            Icons.pool,
            size: (h ?? w ?? 48) * 0.7,
            color: AppColors.primary,
          );
    }

    Widget image = Image.asset(
      _resolvedPath!,
      width: w,
      height: h,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) =>
          widget.fallback ??
          Icon(
            Icons.pool,
            size: (h ?? w ?? 48) * 0.7,
            color: AppColors.primary,
          ),
    );

    // Never zoom full lockup PNGs — zoom was cropping to empty black padding.
    final shouldZoom =
        widget.zoomToMark && !isFullLockup && !_isMarkOnly;
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
