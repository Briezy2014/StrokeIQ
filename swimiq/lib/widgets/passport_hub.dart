import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/passport_ai_recommendation.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/passport_metrics.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../screens/ai_coach/ai_coach_screen.dart';
import '../screens/dryland/ai_dryland_coach_screen.dart';
import '../screens/recruiting/college_recruiting_hub_screen.dart';
import '../screens/race_intelligence/race_intelligence_screen.dart';
import '../screens/swim_dna/swim_dna_screen.dart';
import '../screens/usa_standards/usa_standards_screen.dart';

enum PassportHubLayout {
  /// Full-width stacked intro + links + AI card (narrow screens).
  stacked,

  /// Compact command-center panel for the right column beside the wallet card.
  sidePanel,
}

class PassportHub extends ConsumerWidget {
  const PassportHub({
    super.key,
    required this.data,
    required this.swimmer,
    required this.snapshot,
    this.onOpenRecruitingCenter,
    this.layout = PassportHubLayout.stacked,
    this.showAiCoachCard = true,
  });

  final SwimmerData data;
  final String swimmer;
  final PassportSnapshot snapshot;
  final VoidCallback? onOpenRecruitingCenter;
  final PassportHubLayout layout;
  final bool showAiCoachCard;

  static const _modules = <_PassportModule>[
    _PassportModule(
      label: 'AI Coach',
      destination: PassportHubDestination.aiCoach,
    ),
    _PassportModule(
      label: 'SwimDNA™',
      destination: PassportHubDestination.swimDna,
    ),
    _PassportModule(
      label: 'Recruiting Center',
      destination: PassportHubDestination.recruitingCenter,
    ),
    _PassportModule(
      label: 'Video Lab',
      destination: PassportHubDestination.videoLab,
    ),
    _PassportModule(
      label: 'Race Intelligence™',
      destination: PassportHubDestination.raceIntelligence,
    ),
    _PassportModule(
      label: 'USA Standards',
      destination: PassportHubDestination.usaStandards,
    ),
    _PassportModule(
      label: 'AI Dryland Coach',
      destination: PassportHubDestination.drylandCoach,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = PassportAiRecommendation.build(
      data: data,
      swimmer: swimmer,
    );

    if (layout == PassportHubLayout.sidePanel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HubIntro(compact: true),
          const SizedBox(height: 10),
          _ModuleLinks(
            modules: _modules,
            vertical: true,
            onModuleTap: (module) =>
                _openDestination(context, ref, module.destination),
          ),
          if (showAiCoachCard) ...[
            const SizedBox(height: 12),
            _AiCoachCard(
              recommendation: recommendation,
              readiness: snapshot.readiness,
              swimIqScore: data.swimIqScore,
              onPrimaryAction: () =>
                  _openDestination(context, ref, recommendation.destination),
              compact: true,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HubIntro(),
        const SizedBox(height: 10),
        _ModuleLinks(
          modules: _modules,
          onModuleTap: (module) =>
              _openDestination(context, ref, module.destination),
        ),
        if (showAiCoachCard) ...[
          const SizedBox(height: 12),
          _AiCoachCard(
            recommendation: recommendation,
            readiness: snapshot.readiness,
            swimIqScore: data.swimIqScore,
            onPrimaryAction: () =>
                _openDestination(context, ref, recommendation.destination),
          ),
        ],
      ],
    );
  }

  void _openDestination(
    BuildContext context,
    WidgetRef ref,
    PassportHubDestination destination,
  ) {
    switch (destination) {
      case PassportHubDestination.aiCoach:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiCoachScreen()),
        );
      case PassportHubDestination.videoLab:
        ref.read(homeTabIndexProvider.notifier).state = HomeTab.videoLab;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opened Video Lab')),
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
          MaterialPageRoute(builder: (_) => const SwimDnaScreen()),
        );
      case PassportHubDestination.recruitingCenter:
        if (onOpenRecruitingCenter != null) {
          onOpenRecruitingCenter!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CollegeRecruitingHubScreen(),
            ),
          );
        }
      case PassportHubDestination.drylandCoach:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiDrylandCoachScreen()),
        );
    }
  }
}

class _HubIntro extends StatelessWidget {
  const _HubIntro({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 12 : 14,
        compact ? 14 : 16,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Athlete Passport™ Command Center',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 15 : null,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            compact
                ? 'Open each module from here.'
                : 'Tap a link below to open each module.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _PassportModule {
  const _PassportModule({
    required this.label,
    required this.destination,
  });

  final String label;
  final PassportHubDestination destination;
}

class _ModuleLinks extends StatelessWidget {
  const _ModuleLinks({
    required this.modules,
    required this.onModuleTap,
    this.vertical = false,
  });

  final List<_PassportModule> modules;
  final void Function(_PassportModule module) onModuleTap;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final module in modules) ...[
            _ModuleTile(
              label: module.label,
              onTap: () => onModuleTap(module),
            ),
            const SizedBox(height: 6),
          ],
        ],
      );
    }

    final linkStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary.withValues(alpha: 0.5),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < modules.length; i++) ...[
          if (i > 0)
            Text(
              '·',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          InkWell(
            onTap: () => onModuleTap(modules[i]),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(modules[i].label, style: linkStyle),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.primaryDark.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiCoachCard extends StatelessWidget {
  const _AiCoachCard({
    required this.recommendation,
    required this.readiness,
    required this.swimIqScore,
    required this.onPrimaryAction,
    this.compact = false,
  });

  final PassportAiRecommendation recommendation;
  final String readiness;
  final int swimIqScore;
  final VoidCallback onPrimaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              recommendation.headline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    fontSize: compact ? 15 : null,
                  ),
            ),
            SizedBox(height: compact ? 8 : 10),
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
            SizedBox(height: compact ? 8 : 12),
            Text(
              recommendation.detail,
              maxLines: compact ? 4 : null,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    fontSize: compact ? 13 : null,
                  ),
            ),
            if (!compact) ...[
              const SizedBox(height: 10),
              Text(
                recommendation.engineLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            SizedBox(height: compact ? 12 : 16),
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
