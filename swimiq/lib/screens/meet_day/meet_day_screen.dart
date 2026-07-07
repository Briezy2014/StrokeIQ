import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/meet_day_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/passport_module_ui.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class MeetDayScreen extends ConsumerWidget {
  const MeetDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meet Day Mode')),
      body: SwimmerScreen(
        builder: (context, ref, data, swimmer) {
          final brief = MeetDayService.build(data: data, swimmer: swimmer);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const PassportModuleBanner(
                emoji: '🏊',
                title: 'Meet Day Mode',
                body:
                    'Live race-day toolkit — bag check, warmup timing, event lineup, '
                    'and between-races recovery.',
                accent: Color(0xFF0077C8),
              ),
              const SizedBox(height: 16),
              SwimIqScreenHeader(
                title: brief.headline,
                subtitle: brief.summary,
              ),
              if (brief.meetName != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(brief.meetName!)),
                    if (brief.meetDate != null)
                      Chip(
                        label: Text(MeetDayService.formatMeetDate(brief.meetDate)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Race lineup',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              PassportModuleSection(
                title: 'Events today',
                icon: Icons.event_note,
                lines: brief.raceLineup,
              ),
              PassportModuleSection(
                title: 'Warm-up plan',
                icon: Icons.pool,
                lines: brief.warmupPlan,
              ),
              PassportModuleSection(
                title: 'Between races',
                icon: Icons.timer_outlined,
                lines: brief.betweenRacesTips,
              ),
              Text(
                'Checklist',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              ...brief.checklist.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(item.detail),
                    trailing: Text(
                      item.timing,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
