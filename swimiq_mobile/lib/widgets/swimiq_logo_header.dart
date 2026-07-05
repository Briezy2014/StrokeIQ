import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import 'swimiq_logo.dart';

/// Shared SwimIQ branding block for splash and auth screens.
class SwimIqLogoHeader extends StatelessWidget {
  const SwimIqLogoHeader({
    super.key,
    this.compact = false,
    this.showTagline = true,
  });

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SwimIqLogo(
        variant: SwimIqLogoVariant.logo,
        width: 220,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwimIqLogo(
          variant: showTagline
              ? SwimIqLogoVariant.brandingFull
              : SwimIqLogoVariant.logo,
          width: 280,
        ),
        if (showTagline) ...[
          const SizedBox(height: 12),
          Text(
            AppConstants.appTagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: SwimIqColors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ],
    );
  }
}
