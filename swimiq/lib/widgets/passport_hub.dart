import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/passport_ai_recommendation.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/passport_metrics.dart';
import '../providers/swimmer_data_provider.dart';
import '../screens/video_lab/video_lab_screen.dart';
import '../screens/usa_standards/usa_standards_screen.dart';

class PassportHub extends ConsumerWidget {
  const PassportHub({
    super.key,
    required this.data,
    required this.swimmer,
    required this.snapshot,
  });

  final SwimmerData data;
  final String swimmer;
  final PassportSnapshot snapshot;

  static const hubTagline =
      '🤖 AI Coach   |   🧬 SwimDNA™   |   🎓 Recruiting Center   |   '
      '🎥 Video Lab   |   🏁 Race Intelligence™   |   📊 USA Swimming Standards';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = PassportAiRecommendation.build(
      data: data,
      swimmer: swimmer,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubIntro(tagline: hubTagline),
        const SizedBox(height: 12),
        _ModuleStrip(
          onModuleTap: (module) => _handleModuleTap(context, ref, module),
        ),
        const SizedBox(height: 16),
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
    switch (module.status) {
      case _PassportModuleStatus.live:
        _openDestination(context, ref, module.destination!);
      case _PassportModuleStatus.comingSoon:
        _showComingSoon(context, module);
    }
  }

  void _openDestination(
    BuildContext context,
    WidgetRef ref,
    PassportHubDestination destination,
  ) {
    switch (destination) {
      case PassportHubDestination.videoLab:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VideoLabScreen()),
        );
      case PassportHubDestination.usaStandards:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UsaStandardsScreen()),
        );
      case PassportHubDestination.comingSoon:
        break;
    }
  }

  void _showComingSoon(BuildContext context, _PassportModule module) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${module.emoji} ${module.label}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                module.comingSoonDetail,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Coming soon to Athlete Passport™',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HubIntro extends StatelessWidget {
  const _HubIntro({required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    final segments = tagline.split(RegExp(r'\s{3}\|\s{3}'));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFE8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coming Soon to Athlete Passport™',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0077C8),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                Text(
                  segments[i].trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0B2D4D),
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                ),
                if (i < segments.length - 1)
                  Text(
                    '|',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF0077C8),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

enum _PassportModuleStatus { live, comingSoon }

class _PassportModule {
  const _PassportModule({
    required this.emoji,
    required this.label,
    required this.status,
    this.destination,
    this.comingSoonDetail = '',
  });

  final String emoji;
  final String label;
  final _PassportModuleStatus status;
  final PassportHubDestination? destination;
  final String comingSoonDetail;
}

class _ModuleStrip extends StatelessWidget {
  const _ModuleStrip({required this.onModuleTap});

  final void Function(_PassportModule module) onModuleTap;

  static const modules = <_PassportModule>[
    _PassportModule(
      emoji: '🤖',
      label: 'AI Coach',
      status: _PassportModuleStatus.live,
      destination: PassportHubDestination.videoLab,
    ),
    _PassportModule(
      emoji: '🧬',
      label: 'SwimDNA™',
      status: _PassportModuleStatus.comingSoon,
      comingSoonDetail:
          'Stroke fingerprinting from your PBs, splits, and video trends — '
          'merged with Claude vision when frame analysis ships.',
    ),
    _PassportModule(
      emoji: '🎓',
      label: 'Recruiting Center',
      status: _PassportModuleStatus.comingSoon,
      comingSoonDetail:
          'College recruiting timeline, academic profile, and meet targets '
          'pulled from your passport and USA cuts.',
    ),
    _PassportModule(
      emoji: '🎥',
      label: 'Video Lab',
      status: _PassportModuleStatus.live,
      destination: PassportHubDestination.videoLab,
    ),
    _PassportModule(
      emoji: '🏁',
      label: 'Race Intelligence™',
      status: _PassportModuleStatus.comingSoon,
      comingSoonDetail:
          'Meet-day race plans from your goals, standards gaps, and latest AI analysis.',
    ),
    _PassportModule(
      emoji: '📊',
      label: 'USA Standards',
      status: _PassportModuleStatus.live,
      destination: PassportHubDestination.usaStandards,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final module = modules[index];
          final isComingSoon = module.status == _PassportModuleStatus.comingSoon;

          return InkWell(
            onTap: () => onModuleTap(module),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 132,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isComingSoon
                    ? Colors.grey.shade100
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isComingSoon
                      ? Colors.grey.shade300
                      : AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(module.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    module.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          height: 1.15,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isComingSoon ? 'Coming Soon' : 'Open',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isComingSoon
                              ? Colors.grey.shade700
                              : AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
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
