import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/services/ai_dryland_coach_service.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';

class AiDrylandCoachScreen extends ConsumerWidget {
  const AiDrylandCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = Navigator.of(context).canPop();

    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.pro,
      title: 'Unlock SwimIQ Pro',
      message: SubscriptionCapabilities.proGateMessage(
        feature: 'AI Dryland Coach',
      ),
      teaserFeatures: const [
        'Personalized dryland workouts',
        'Strength, core & mobility plans',
        'Injury prevention, stability & recovery guidance',
        'Official PBs, meets & Athlete Passport',
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: canPop
            ? AppBar(
                title: const Text('AI Dryland Coach'),
                backgroundColor: AppColors.primaryDeep,
                foregroundColor: Colors.white,
              )
            : null,
        body: SwimmerScreen(
          builder: (context, ref, data, swimmer) {
            final plan =
                AiDrylandCoachService.build(data: data, swimmer: swimmer);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                SwimIqPageHero(
                  title: 'AI Dryland Coach',
                  subtitle: plan.headline,
                  tone: SwimIqPageHeroTone.onPrimary,
                ),
                const SizedBox(height: 16),
                _VideoTechniqueLoopBanner(plan: plan),
                const SizedBox(height: 12),
                _FocusCard(
                  title: 'Primary stroke focus',
                  body: '${plan.primaryStroke} · ${plan.focusEvent}',
                  icon: Icons.fitness_center,
                ),
                const SizedBox(height: 12),
                _FocusCard(
                  title: 'This week’s pool load',
                  body: plan.sessionsThisWeek == 0
                      ? 'No logged sessions this week yet — keep dryland short and crisp.'
                      : '${plan.sessionsThisWeek} logged session${plan.sessionsThisWeek == 1 ? '' : 's'} this week. Recovery guidance below matches that load.',
                  icon: Icons.pool_outlined,
                ),
                const SizedBox(height: 12),
                ...plan.workoutBlocks.map(
                  (block) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutCard(block: block),
                  ),
                ),
                _FocusCard(
                  title: 'Recovery recommendations',
                  body: plan.recoveryNotes,
                  icon: Icons.spa_outlined,
                ),
                const SizedBox(height: 12),
                _FocusCard(
                  title: 'Injury prevention & stability',
                  body: plan.injuryPreventionAndStability,
                  icon: Icons.health_and_safety_outlined,
                ),
                const SizedBox(height: 12),
                Text(
                  plan.engineLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
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

class _VideoTechniqueLoopBanner extends StatelessWidget {
  const _VideoTechniqueLoopBanner({required this.plan});

  final AiDrylandCoachPlan plan;

  @override
  Widget build(BuildContext context) {
    final active = plan.hasVideoTechniqueLoop;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textDark.withValues(alpha: 0.82),
          height: 1.35,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );
    final cueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textDark,
          height: 1.35,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? const Color(0xFF6EE7B7)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dryland ↔ video loop',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            active
                ? 'This plan includes a technique-informed block tied to your latest AI priorities.'
                : 'Analyze a race clip in Video Lab — dryland will add a technique-informed block from those priorities.',
            style: bodyStyle,
          ),
          if (active) ...[
            const SizedBox(height: 10),
            ...plan.videoPriorities.take(3).map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.videocam_outlined,
                        size: 16,
                        color: AppColors.primaryDeep.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p,
                        style: cueStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          fontSize: 14,
                          color: AppColors.textDark.withValues(alpha: 0.88),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.block});

  final DrylandWorkoutBlock block;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                    fontSize: 15,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              block.focus,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            ...block.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: AppColors.primaryDeep,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        exercise,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.textDark.withValues(alpha: 0.9),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              block.notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
