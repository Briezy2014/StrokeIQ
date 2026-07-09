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
        const SwimIqHeroBanner(height: 160, borderRadius: 24),
        const SizedBox(height: 12),
        Text(
          AppConstants.trademark,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
        ),
        if (AppConstants.tagline.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            AppConstants.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
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

/// Full-width SwimIQ hero branding for the app bar.
class SwimIqAppBarBrand extends StatelessWidget {
  const SwimIqAppBarBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SwimIqHeroBanner(height: 56, borderRadius: 12),
    );
  }
}

/// Secondary screens (Settings, Membership, Legal): mark + screen label.
class SwimIqScreenAppBarTitle extends StatelessWidget {
  const SwimIqScreenAppBarTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SwimIqCompactMark(size: 32, borderRadius: 8),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// App bar: swimmer name only — full branding lives in the tab banner strip below.
class SwimIqAppBarTitle extends StatelessWidget {
  const SwimIqAppBarTitle({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final name = subtitle?.trim();
    return Text(
      name != null && name.isNotEmpty ? name : 'SwimIQ',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
    );
  }
}
