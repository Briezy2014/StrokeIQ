import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/utils/motivational_cut.dart';
import '../core/utils/swim_event_parser.dart';
import '../core/utils/swim_time.dart';
import '../data/models/meet_result.dart';
import '../data/models/swimmer_profile.dart';
import '../data/models/swim_schedule_entry.dart';
import '../providers/swimmer_data_provider.dart';
import '../screens/membership/membership_screen.dart';
import '../screens/race_intelligence/race_intelligence_screen.dart';
import 'meet_result_form_sheet.dart';
import 'schedule_depository_section.dart';
import 'swimiq_event_card.dart';

/// Meets & results inside the Log tab — schedules, official times, photo upload.
class MeetsAndResultsPanel extends ConsumerWidget {
  const MeetsAndResultsPanel({
    super.key,
    required this.meetResults,
    required this.schedules,
    required this.showProFeatures,
    required this.highestCut,
    required this.motivationalStandards,
    required this.profile,
  });

  final List<MeetResult> meetResults;
  final List<SwimScheduleEntry> schedules;
  final bool showProFeatures;
  final String highestCut;
  final UsaMotivationalStandardsCatalog motivationalStandards;
  final SwimmerProfile? profile;

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    SwimScheduleEntry entry,
  ) async {
    if (entry.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove entry?'),
        content: Text('Delete ${entry.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error =
        await ref.read(swimmerDataProvider.notifier).deleteSchedule(entry.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Entry removed.')),
    );
  }

  Future<void> _deleteResult(
    BuildContext context,
    WidgetRef ref,
    MeetResult result,
  ) async {
    if (result.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meet result?'),
        content: Text('Remove ${result.event} at ${result.meetName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await ref
        .read(swimmerDataProvider.notifier)
        .deleteMeetResult(result.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Meet result deleted.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat.yMMMd();
    final scheduleTypes = {
      SwimScheduleEntry.typeMeet,
      SwimScheduleEntry.typeRace,
    };
    final filteredSchedules = schedules
        .where((e) => scheduleTypes.contains(e.scheduleType))
        .toList();
    final hasContent = meetResults.isNotEmpty || filteredSchedules.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDeep.withValues(alpha: 0.08),
                      AppColors.surfaceLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Meets & results',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDeep,
                                ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const RaceIntelligenceScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Race plan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Log official times, schedule meets, and upload heat sheets '
                      'or results photos — all in one place.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textDark.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!hasContent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Nothing logged yet. Tap Log meet result to add your first '
                    'official time, or upload a heat sheet photo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.65),
                        ),
                  ),
                ),
              if (showProFeatures && meetResults.isNotEmpty) ...[
                Text(
                  'Official meet times',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (highestCut.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Top cut: $highestCut',
                      style: TextStyle(
                        color: AppColors.primaryDeep.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ...meetResults.map((result) {
                  final parts = SwimEventParser.parse(result.event);
                  final cut = parts == null
                      ? null
                      : MotivationalCut.labelForSwim(
                          catalog: motivationalStandards,
                          profile: profile,
                          stroke: parts.stroke,
                          distance: parts.distance,
                          course: result.course,
                          timeSeconds: result.swimTime,
                        );
                  return SwimIqEventCard(
                    title: result.event,
                    subtitle:
                        '${result.meetName} · ${dateFormat.format(result.meetDate)} · '
                        '${cut ?? 'Below B'} cut',
                    highlight: cut == highestCut,
                    trailingActions: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            SwimTime.fromSeconds(result.swimTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteResult(context, ref, result);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ] else if (!showProFeatures) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium,
                        color: AppColors.primary),
                    title: const Text(
                      'Official meet times & USA cuts',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Upgrade to Pro to log official meet results with motivational standards.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MembershipScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (filteredSchedules.isNotEmpty) ...[
                Text(
                  'Scheduled meets & uploaded results',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...filteredSchedules.map(
                  (entry) => ScheduleEntryTile(
                    entry: entry,
                    dateFormat: dateFormat,
                    onDelete: () => _deleteSchedule(context, ref, entry),
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (showProFeatures)
                  FilledButton.icon(
                    onPressed: () => showMeetResultFormSheet(context),
                    icon: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: const Text('Log meet result'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MembershipScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: const Text('Log meet result'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (showProFeatures) {
                      showMeetResultFormSheet(context, startWithPhotoPicker: true);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MembershipScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Upload photo'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
