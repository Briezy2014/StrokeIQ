import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/race_intelligence_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

/// Meet-specific race plans, pacing, and event strategy.
class RaceIntelligenceScreen extends ConsumerWidget {
  const RaceIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Intelligence™'),
      ),
      body: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final brief =
              RaceIntelligenceService.build(data: data, swimmer: swimmer);
          final dateFormat = DateFormat.yMMMd();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _RoleBanner(
                emoji: '🏁',
                title: 'Race Intelligence™',
                body:
                    'Meet-day strategy — pacing, race plans, and event tips. '
                    'Different from AI Coach (technique fixes) and Video Lab '
                    '(full video critique).',
                accent: Color(0xFF0077C8),
              ),
              const SizedBox(height: 16),
              SwimIqScreenHeader(
                title: brief.headline,
                subtitle: brief.summary,
              ),
              if (brief.nextMeetDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  brief.nextMeetName != null
                      ? 'Next focus: ${brief.nextMeetName} · ${dateFormat.format(brief.nextMeetDate!)}'
                      : 'Target date: ${dateFormat.format(brief.nextMeetDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Meet day checklist',
                icon: Icons.checklist_rtl,
                lines: brief.meetDayTips,
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Warmup plan',
                icon: Icons.pool_outlined,
                lines: brief.warmupTips,
              ),
              const SizedBox(height: 20),
              Text(
                'Race plans',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (brief.racePlans.isEmpty)
                const EmptyStateMessage(
                  message: 'Add goals with meet dates to build race plans.',
                )
              else
                ...brief.racePlans.map(
                  (plan) => _RacePlanCard(plan: plan, dateFormat: dateFormat),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleBanner extends StatelessWidget {
  const _RoleBanner({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String emoji;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

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
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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

class _RacePlanCard extends StatelessWidget {
  const _RacePlanCard({
    required this.plan,
    required this.dateFormat,
  });

  final RaceIntelligencePlan plan;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan.event} · ${plan.course}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.headline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (plan.targetDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Target date: ${dateFormat.format(plan.targetDate!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (plan.goalTime != null || plan.currentPb != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  if (plan.goalTime != null) Chip(label: Text('Goal ${plan.goalTime}')),
                  if (plan.currentPb != null) Chip(label: Text('PB ${plan.currentPb}')),
                  if (plan.standardsTarget != null)
                    Chip(label: Text('Cut ${plan.standardsTarget}')),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              plan.strategy,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            ...plan.raceTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('→ '),
                    Expanded(child: Text(tip)),
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
