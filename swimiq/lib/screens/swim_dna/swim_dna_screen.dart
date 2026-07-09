import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/services/swim_dna_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';

class SwimDnaScreen extends ConsumerWidget {
  const SwimDnaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwimIqFeatureScaffold(
      title: 'SwimDNA™',
      body: SubscriptionGatedScreen(
        minimumTier: SubscriptionTier.pro,
        title: 'Unlock SwimIQ Pro',
        message:
            'SwimDNA™ is included with Pro — your stroke identity, readiness, '
            'cuts, IMX/IMR, and coaching signals in one profile.',
        teaserFeatures: const [
          'Athlete Passport & recruiting snapshot',
          'Official PBs, meet results & USA standards',
          'SwimDNA™ athlete identity profile',
          'Video Lab uploads & organization',
        ],
        child: SwimmerScreen(
          builder: (context, ref, data, swimmer) {
            final profile = SwimDnaService.build(data: data, swimmer: swimmer);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                SwimIqPageHero(
                  title: 'SwimDNA™',
                  subtitle: profile.subtitle,
                ),
                const SizedBox(height: 12),
                _DnaHeroCard(profile: profile),
                const SizedBox(height: 16),
                Text(
                  'Your swimming traits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 8),
                ...profile.traits.map(
                  (trait) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TraitCard(trait: trait),
                  ),
                ),
                const SizedBox(height: 8),
                _BulletSection(
                  title: 'Strengths in your DNA',
                  lines: profile.strengths,
                  icon: Icons.bolt_outlined,
                ),
                const SizedBox(height: 12),
                _BulletSection(
                  title: 'Growth edges',
                  lines: profile.growthEdges,
                  icon: Icons.trending_up,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.engineLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DnaHeroCard extends StatelessWidget {
  const _DnaHeroCard({required this.profile});

  final SwimDnaProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.headline,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraitCard extends StatelessWidget {
  const _TraitCard({required this.trait});

  final SwimDnaTrait trait;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trait.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              trait.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              trait.insight,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.lines,
    required this.icon,
  });

  final String title;
  final List<String> lines;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
