import 'package:flutter/material.dart';

import 'swimiq_logo.dart';

/// App bar title row with the SwimIQ wordmark logo.
class SwimIqAppBarTitle extends StatelessWidget {
  const SwimIqAppBarTitle({
    super.key,
    this.subtitle,
    this.logoHeight = 28,
  });

  final String? subtitle;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    if (subtitle == null) {
      return SwimIqLogo(
        variant: SwimIqLogoVariant.logo,
        height: logoHeight,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwimIqLogo(
          variant: SwimIqLogoVariant.logo,
          height: logoHeight,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                letterSpacing: 0.4,
              ),
        ),
      ],
    );
  }
}

/// Branded [AppBar] used across main app screens.
class SwimIqAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SwimIqAppBar({
    super.key,
    this.subtitle,
    this.actions,
    this.showLogo = true,
  });

  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogo;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? kToolbarHeight : 72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: showLogo
          ? SwimIqAppBarTitle(subtitle: subtitle)
          : Text(subtitle ?? ''),
      actions: actions,
    );
  }
}
