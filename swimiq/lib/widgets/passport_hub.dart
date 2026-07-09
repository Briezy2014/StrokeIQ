import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/passport_ai_recommendation.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/passport_metrics.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../screens/recruiting/college_recruiting_hub_screen.dart';
import '../screens/race_intelligence/race_intelligence_screen.dart';
import '../screens/usa_standards/usa_standards_screen.dart';

class PassportHub extends ConsumerWidget {
  const PassportHub({
    super.key,
    required this.data,
    required this.swimmer,
    required this.snapshot,
    this.onOpenRecruitingCenter,
  });

  final SwimmerData data;
  final String swimmer;
  final PassportSnapshot snapshot;
  final VoidCallback? onOpenRecruitingCenter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = PassportAiRecommendation.build(
      data: data,
      swimmer: swimmer,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubIntro(),
        const SizedBox(height: 12),
        _ModuleGrid(
          onModuleTap: (module) => _handleModuleTap(context, ref, module),
        ),
        const SizedBox(height: 12),
        _AiCoachCard(
          recommendation: recommendation,
          readiness: snapshot.readiness,
          swimIqScore: data.swimIqScore,
          onPrimaryAction: () => _openDestination(context, ref, recommendation.destination),
        ),
      ],
    );
  }

  void _handleModuleTap(
    BuildContext context,
    WidgetRef ref,
    _PassportModule module,
  ) {
    _openDestination(context, ref, module.destination);
  }

  void _openDestination(
    BuildContext context,
    WidgetRef ref,
    PassportHubDestination destination,
  ) {
    switch (destination) {
      case PassportHubDestination.videoLab:
        ref.read(homeTabIndexProvider.notifier).state = HomeTab.videoLab;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opened Video Lab from Athlete Passport™')),
        );
      case PassportHubDestination.usaStandards:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UsaStandardsScreen()),
        );
      case PassportHubDestination.raceIntelligence:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RaceIntelligenceScreen()),
        );
      case PassportHubDestination.swimDna:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RaceIntelligenceScreen()),
        );
      case PassportHubDestination.recruitingCenter:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CollegeRecruitingHubScreen()),
        );
    }
  }
}

class _HubIntro extends StatelessWidget {
  const _HubIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Athlete Passport™ Command Center',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Live now — tap any module to open.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PassportModule {
  const _PassportModule({
    required this.emoji,
    required this.label,
    required this.destination,
  });

  final String emoji;
  final String label;
  final PassportHubDestination destination;
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.onModuleTap});

  final void Function(_PassportModule module) onModuleTap;

  static const modules = <_PassportModule>[
    _PassportModule(
      emoji: '🤖',
      label: 'AI Coach',
      destination: PassportHubDestination.videoLab,
    ),
    _PassportModule(
      emoji: '🧬',
      label: 'SwimDNA™',
      destination: PassportHubDestination.swimDna,
    ),
    _PassportModule(
      emoji: '🎓',
      label: 'Recruiting Center',
      destination: PassportHubDestination.recruitingCenter,
    ),
    _PassportModule(
      emoji: '🎥',
      label: 'Video Lab',
      destination: PassportHubDestination.videoLab,
    ),
    _PassportModule(
      emoji: '🏁',
      label: 'Race Intelligence™',
      destination: PassportHubDestination.raceIntelligence,
    ),
    _PassportModule(
      emoji: '📊',
      label: 'USA Standards',
      destination: PassportHubDestination.usaStandards,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];

            return InkWell(
              onTap: () => onModuleTap(module),
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.emoji, style: const TextStyle(fontSize: 22)),
                    const Spacer(),
                    Text(
                      module.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AiCoachCard extends StatelessWidget {
  const _AiCoachCard({
    required this.recommendation,
    required this.readiness,
    required this.swimIqScore,
    required this.onPrimaryAction,
  });

  final PassportAiRecommendation recommendation;
  final String readiness;
  final int swimIqScore;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.headline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: readiness),
                _Chip(label: 'SwimIQ $swimIqScore'),
                if (recommendation.suggestedEvent != null)
                  _Chip(label: recommendation.suggestedEvent!),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              recommendation.engineLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPrimaryAction,
              icon: const Icon(Icons.auto_awesome),
              label: Text(recommendation.actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
      ),
    );
  }
}
