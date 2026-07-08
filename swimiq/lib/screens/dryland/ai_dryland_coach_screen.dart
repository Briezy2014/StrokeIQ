import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/swimiq_quotes.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/services/ai_dryland_coach_service.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';

class AiDrylandCoachScreen extends ConsumerWidget {
  const AiDrylandCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.pro,
      title: 'Unlock SwimIQ Pro',
      message: SubscriptionCapabilities.proGateMessage(
        feature: 'AI Dryland Coach',
      ),
      teaserFeatures: const [
        'Personalized dryland workouts',
        'Strength, core & mobility plans',
        'Injury prevention & recovery guidance',
        'Official PBs, meets & Athlete Passport',
      ],
      child: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final plan = AiDrylandCoachService.build(data: data, swimmer: swimmer);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SwimIqPageHero(
                title: 'AI Dryland Coach',
                subtitle: plan.headline,
                quote: SwimIqQuotes.pickFor(swimmer, SwimIqQuotes.trainingLog),
              ),
              const SizedBox(height: 16),
              _FocusCard(
                title: 'Primary stroke focus',
                body: plan.primaryStroke,
                icon: Icons.fitness_center,
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
                title: 'Injury prevention',
                body: plan.injuryPrevention,
                icon: Icons.health_and_safety_outlined,
              ),
              const SizedBox(height: 12),
              Text(
                plan.engineLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          );
        },
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
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(height: 1.4)),
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
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              block.focus,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...block.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(exercise)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              block.notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
