import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/swimiq_quotes.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/services/race_intelligence_service.dart';
import '../../core/subscription/subscription_capabilities.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class RaceIntelligenceScreen extends ConsumerStatefulWidget {
  const RaceIntelligenceScreen({super.key});

  @override
  ConsumerState<RaceIntelligenceScreen> createState() =>
      _RaceIntelligenceScreenState();
}

class _RaceIntelligenceScreenState extends ConsumerState<RaceIntelligenceScreen> {
  final Set<int> _checkedItems = {};

  @override
  Widget build(BuildContext context) {
    return SubscriptionGatedScreen(
      minimumTier: SubscriptionTier.elite,
      title: 'Unlock SwimIQ Elite',
      message: 'Race Intelligence is included with Elite — race pacing, split analysis, '
          'tempo trends, fatigue detection, and AI race strategy.',
      teaserFeatures: const [
        'AI Stroke Analysis — mechanics, kick, turns & more',
        'Race Intelligence — pacing, splits & fatigue detection',
        'AI Performance Reports & race strategy',
      ],
      child: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
        final plan = RaceIntelligenceService.build(
          data: data,
          swimmer: swimmer,
        );

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              title: 'Race Intelligence',
              subtitle: plan.meetDayLabel,
              quote: SwimIqQuotes.pickFor(swimmer, SwimIqQuotes.raceIntelligence),
            ),
            const SizedBox(height: 12),
            _HeroCard(plan: plan),
            const SizedBox(height: 20),
            _SectionTitle('Midday meet checklist'),
            const SizedBox(height: 8),
            ...plan.middayChecklist.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final checked = _checkedItems.contains(index);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: checked,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _checkedItems.add(index);
                      } else {
                        _checkedItems.remove(index);
                      }
                    });
                  },
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration:
                          checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item.detail),
                      const SizedBox(height: 6),
                      Text(
                        item.timingHint,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }),
            const SizedBox(height: 16),
            _SectionTitle('Warm-up plan'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plan.warmUpPlan
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  '),
                              Expanded(child: Text(line)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle('SwimIQ AI Nutrition plan'),
            const SizedBox(height: 8),
            ...plan.nutritionPlan.map(
              (block) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.mealLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        block.timing,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ...block.suggestions.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✓ '),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Avoid: ${block.avoid}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              color: AppColors.surfaceLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(plan.hydrationNotes),
              ),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.plan});

  final RaceIntelligencePlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.accent,
            AppColors.surfaceLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.headline,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Focus event: ${plan.focusEvent}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroChip(label: 'Midday checklist'),
              _HeroChip(label: 'Warm-up plan'),
              _HeroChip(label: 'AI nutrition'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white54),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
    );
  }
}
