import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import 'swimiq_brand_background.dart';
import 'swimiq_brand_typography.dart';
import 'swimiq_logo.dart';

class SwimIqHeader extends StatelessWidget {
  const SwimIqHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const SwimIqHeroBanner(height: 160, borderRadius: 24),
        const SizedBox(height: 16),
        const SwimIqWordmark(fontSize: 28),
        const SizedBox(height: 8),
        const SwimIqTagline(fontSize: 18),
        const SizedBox(height: 6),
        const SwimIqFounderLine(),
        const SizedBox(height: 16),
        Divider(color: AppColors.accent.withValues(alpha: 0.25)),
      ],
    );
  }
}

class SwimIqFooter extends StatelessWidget {
  const SwimIqFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primary.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Column(
        children: [
          const SwimIqWordmark(fontSize: 14),
          const SizedBox(height: 4),
          Text(
            AppConstants.copyright,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class SwimIqAppBarTitle extends StatelessWidget {
  const SwimIqAppBarTitle({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SwimIqLogo(size: 36, borderRadius: 10),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SwimIqWordmark(fontSize: 17, onDark: true),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
