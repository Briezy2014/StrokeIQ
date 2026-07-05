import 'package:flutter/material.dart';

import '../core/assets.dart';

/// Which SwimIQ brand asset to display.
enum SwimIqLogoVariant {
  /// Graphic only (app icon).
  appIcon,

  /// Icon + SWIMIQ wordmark.
  logo,

  /// Icon, wordmark, signature, and tagline.
  brandingFull,
}

/// Reusable SwimIQ logo widget backed by official image assets.
class SwimIqLogo extends StatelessWidget {
  const SwimIqLogo({
    super.key,
    this.variant = SwimIqLogoVariant.logo,
    this.width,
    this.height,
  });

  final SwimIqLogoVariant variant;
  final double? width;
  final double? height;

  String get _assetPath {
    switch (variant) {
      case SwimIqLogoVariant.appIcon:
        return SwimIqAssets.appIcon;
      case SwimIqLogoVariant.logo:
        return SwimIqAssets.logo;
      case SwimIqLogoVariant.brandingFull:
        return SwimIqAssets.brandingFull;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
