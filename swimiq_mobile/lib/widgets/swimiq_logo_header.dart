import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// Shared SwimIQ branding widget used on splash and auth screens.
class SwimIqLogoHeader extends StatelessWidget {
  const SwimIqLogoHeader({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 56.0 : 88.0;
    final titleStyle = compact
        ? Theme.of(context).textTheme.headlineSmall
        : Theme.of(context).textTheme.headlineMedium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize + 24,
          height: iconSize + 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SwimIqColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.pool_rounded,
            size: iconSize,
            color: SwimIqColors.primary,
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: titleStyle?.copyWith(
            fontWeight: FontWeight.bold,
            color: SwimIqColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.appTagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: SwimIqColors.navy,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
