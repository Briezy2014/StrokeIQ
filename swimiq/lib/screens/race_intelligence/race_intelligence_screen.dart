import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subscription_plan.dart';
import '../../core/services/race_intelligence_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/subscription_upgrade_panel.dart';
import '../../widgets/swim_iq_feature_scaffold.dart';
import '../../widgets/swimmer_screen.dart';

class RaceIntelligenceScreen extends ConsumerStatefulWidget {
  const RaceIntelligenceScreen({super.key});

  @override
  ConsumerState<RaceIntelligenceScreen> createState() =>
      _RaceIntelligenceScreenState();
}

class _RaceIntelligenceScreenState extends ConsumerState<RaceIntelligenceScreen> {
  final Set<int> _checkedItems = {};
  final Set<String> _pickedFuel = {};
  String? _selectedFocusEvent;

  @override
  Widget build(BuildContext context) {
    return SwimIqFeatureScaffold(
      title: 'Race Intelligence',
      body: SubscriptionGatedScreen(
        minimumTier: SubscriptionTier.elite,
        title: 'Unlock SwimIQ Elite',
        message:
            'Race Intelligence is included with Elite — meet-day plans synced to your schedule, '
            'multi-event warm-ups, and AI nutrition choices.',
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
              selectedFocusEvent: _selectedFocusEvent,
            );
            final events = plan.meetEvents;
            final selected = events.contains(plan.focusEvent)
                ? plan.focusEvent
                : (events.isNotEmpty ? events.first : plan.focusEvent);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _PageHeader(plan: plan),
                const SizedBox(height: 14),
                _MeetSyncCard(plan: plan),
                const SizedBox(height: 14),
                _EventChooser(
                  events: events,
                  selected: selected,
                  onSelected: (event) {
                    setState(() {
                      _selectedFocusEvent = event;
                      _checkedItems.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _SectionTitle('Meet-day timeline'),
                const SizedBox(height: 8),
                _TimelineGraphic(steps: plan.timeline),
                const SizedBox(height: 18),
                _SectionTitle('Midday meet checklist'),
                const SizedBox(height: 8),
                ...plan.middayChecklist.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final checked = _checkedItems.contains(index);
                  return Card(
                    color: Colors.white,
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
                          color: AppColors.textDark,
                          decoration:
                              checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            item.detail,
                            style: TextStyle(
                              color: AppColors.textDark.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.timingHint,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.primaryDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _SectionTitle('Dryland warm-up'),
                const SizedBox(height: 4),
                Text(
                  'Tap through phases before pool warm-up — tuned for $selected.',
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ...plan.warmUpPhases.map(
                  (phase) => _WarmUpPhaseCard(phase: phase),
                ),
                const SizedBox(height: 16),
                _SectionTitle('SwimIQ AI Nutrition — choose your fuel'),
                const SizedBox(height: 4),
                Text(
                  'Tap options you want on meet day. Your picks stay highlighted below.',
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ...plan.nutritionPlan.map(
                  (block) => _NutritionChoiceCard(
                    block: block,
                    picked: _pickedFuel,
                    onToggle: (item) {
                      setState(() {
                        if (_pickedFuel.contains(item)) {
                          _pickedFuel.remove(item);
                        } else {
                          _pickedFuel.add(item);
                        }
                      });
                    },
                  ),
                ),
                if (_pickedFuel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surfaceLight,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your meet-day fuel picks',
                            style: TextStyle(
                              color: AppColors.primaryDeep,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in _pickedFuel)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $item',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      plan.hydrationNotes,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  plan.engineLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.65),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.plan});

  final RaceIntelligencePlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.syncedToSchedule
                ? 'Synced to ${plan.meetDayLabel}'
                : 'Build a next-meet plan — add a meet on Log → Schedule to sync automatically.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetSyncCard extends StatelessWidget {
  const _MeetSyncCard({required this.plan});

  final RaceIntelligencePlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                plan.syncedToSchedule
                    ? Icons.event_available
                    : Icons.event_busy_outlined,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.syncedToSchedule
                        ? (plan.meetTitle ?? 'Upcoming meet')
                        : 'No upcoming meet synced yet',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      plan.meetDayLabel,
                      if (plan.meetStartTime?.trim().isNotEmpty == true)
                        plan.meetStartTime!.trim(),
                      if (plan.meetLocation?.trim().isNotEmpty == true)
                        plan.meetLocation!.trim(),
                    ].join(' · '),
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
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

class _EventChooser extends StatelessWidget {
  const _EventChooser({
    required this.events,
    required this.selected,
    required this.onSelected,
  });

  final List<String> events;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Events for this plan',
              style: TextStyle(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick the event to tune warm-up cues & fueling. Other meet events stay listed.',
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final event in events)
                  ChoiceChip(
                    label: Text(event),
                    selected: event == selected,
                    onSelected: (_) => onSelected(event),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: event == selected
                          ? AppColors.primaryDeep
                          : AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineGraphic extends StatelessWidget {
  const _TimelineGraphic({required this.steps});

  final List<RaceTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryDeep,
                              AppColors.primary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconFor(steps[i].iconName),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 3,
                          height: 28,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < steps.length - 1 ? 8 : 0,
                        top: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].label,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            steps[i].detail,
                            style: TextStyle(
                              color: AppColors.textDark.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'breakfast':
        return Icons.free_breakfast_outlined;
      case 'arrive':
        return Icons.location_on_outlined;
      case 'warmup':
        return Icons.fitness_center;
      case 'race':
        return Icons.pool;
      case 'recover':
        return Icons.self_improvement;
      default:
        return Icons.circle;
    }
  }
}

class _WarmUpPhaseCard extends StatelessWidget {
  const _WarmUpPhaseCard({required this.phase});

  final WarmUpPhase phase;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '${phase.phaseNumber}',
                style: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          phase.title,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          phase.duration,
                          style: const TextStyle(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phase.detail,
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
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

class _NutritionChoiceCard extends StatelessWidget {
  const _NutritionChoiceCard({
    required this.block,
    required this.picked,
    required this.onToggle,
  });

  final NutritionBlock block;
  final Set<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.mealLabel,
              style: const TextStyle(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              block.timing,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in block.suggestions)
                  FilterChip(
                    label: Text(
                      item.length > 42 ? '${item.substring(0, 42)}…' : item,
                    ),
                    selected: picked.contains(item),
                    onSelected: (_) => onToggle(item),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.primaryDeep,
                    labelStyle: TextStyle(
                      color: picked.contains(item)
                          ? AppColors.primaryDeep
                          : AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Avoid: ${block.avoid}',
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
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
