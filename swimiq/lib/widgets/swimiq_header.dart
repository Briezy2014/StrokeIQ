import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'swimiq_logo.dart';

class SwimIqHeader extends StatelessWidget {
  const SwimIqHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const SwimIqLogo(size: 120, borderRadius: 24),
        const SizedBox(height: 12),
        Text(
          AppConstants.trademark,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConstants.tagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConstants.founder,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}

class SwimIqFooter extends StatelessWidget {
  const SwimIqFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        AppConstants.copyright,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
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
        const SwimIqLogo(size: 32, borderRadius: 8),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SwimIqWordmark(fontSize: 16),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
