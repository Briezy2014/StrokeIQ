import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../data/models/swim_schedule_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/schedule_depository_section.dart';
import '../../widgets/swim_session_form_sheet.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../race_intelligence/race_intelligence_screen.dart';

/// Training log with sessions plus schedule/meet depository.
class TrainingLogScreen extends ConsumerStatefulWidget {
  const TrainingLogScreen({super.key});

  @override
  ConsumerState<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends ConsumerState<TrainingLogScreen> {
  int get _tabIndex => ref.watch(trainingLogSegmentProvider);

  void _setTabIndex(int index) {
    ref.read(trainingLogSegmentProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final logs = data.raceLogs;
        final dateFormat = DateFormat.yMMMd();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwimIqPageHero(
                    title: 'Log',
                    subtitle: 'Training, practices, meets & results',
                    stats: [
                      SwimIqHeroStat('${logs.length} sessions'),
                      SwimIqHeroStat('${data.schedules.length} schedule items'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Training & practices'),
                      ),
                      ButtonSegment(value: 1, label: Text('Meets & results')),
                    ],
                    selected: {_tabIndex},
                    onSelectionChanged: (values) {
                      _setTabIndex(values.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tabIndex == 0
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _TrainingTabPanel(
                        logs: logs,
                        practices: data.schedules
                            .where(
                              (entry) =>
                                  entry.scheduleType ==
                                  SwimScheduleEntry.typePractice,
                            )
                            .toList(),
                        dateFormat: dateFormat,
                        onEditLog: (log) => _editLog(context, ref, log),
                        onDeleteLog: (log) => _deleteLog(context, ref, log),
                        onDeletePractice: (entry) =>
                            _deletePractice(context, ref, entry),
                        onLogSwim: () => showSwimSessionFormSheet(context),
                        onUploadSwimPhoto: () =>
                            showSwimSessionFormSheet(context, startWithPhotoPicker: true),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ScheduleDepositorySection(
                        showTypes: {
                          SwimScheduleEntry.typeMeet,
                          SwimScheduleEntry.typeRace,
                        },
                        addTypes: {
                          SwimScheduleEntry.typeMeet,
                          SwimScheduleEntry.typeRace,
                        },
                        headerTitle: 'Meets & results',
                        headerSubtitle:
                            'Saved meets and race results. Add manually or '
                            'upload a heat sheet / results photo.',
                        emptyMessage:
                            'No meets or results yet. Tap a button below to add one.',
                        onOpenRaceIntelligence: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RaceIntelligenceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePractice(
    BuildContext context,
    WidgetRef ref,
    SwimScheduleEntry entry,
  ) async {
    if (entry.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove practice schedule?'),
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
      SnackBar(content: Text(error ?? 'Practice schedule removed.')),
    );
  }

  Future<void> _deleteLog(
    BuildContext context,
    WidgetRef ref,
    RaceLog log,
  ) async {
    if (log.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete swim session?'),
        content: Text(
          'Remove ${log.distance} ${log.stroke} · '
          '${SwimTime.fromSeconds(log.timeSeconds)}?',
        ),
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
        await ref.read(swimmerDataProvider.notifier).deleteRaceLog(log.id!);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Swim session deleted.')),
    );
  }

  Future<void> _editLog(
    BuildContext context,
    WidgetRef ref,
    RaceLog log,
  ) async {
    if (log.id == null) return;

    final timeController =
        TextEditingController(text: SwimTime.fromSeconds(log.timeSeconds));
    final notesController = TextEditingController(text: log.notes ?? '');
    final distanceController = TextEditingController(text: '${log.distance}');
    var stroke = log.stroke;
    var course = log.course;
    var sessionDate = log.date;
    final dateFormat = DateFormat.yMMMd();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit swim session'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey('stroke-$stroke'),
                    initialValue: AppConstants.strokes.contains(stroke)
                        ? stroke
                        : AppConstants.strokes.first,
                    decoration: const InputDecoration(labelText: 'Stroke'),
                    items: AppConstants.strokes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => stroke = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: distanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Distance'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('course-$course'),
                    initialValue: course,
                    decoration: const InputDecoration(labelText: 'Course'),
                    items: AppConstants.courses
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => course = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      hintText: '35.43 or 1:24.32',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(dateFormat.format(sessionDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: sessionDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => sessionDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || !context.mounted) {
      timeController.dispose();
      notesController.dispose();
      distanceController.dispose();
      return;
    }

    try {
      final distance = int.parse(distanceController.text);
      final timeSeconds = SwimTime.toSeconds(timeController.text);
      final updated = RaceLog(
        id: log.id,
        swimmer: log.swimmer,
        event: '$distance $stroke',
        distance: distance,
        stroke: stroke,
        course: course,
        timeSeconds: timeSeconds,
        date: sessionDate,
        notes: notesController.text.trim(),
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).updateRaceLog(updated);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Swim session updated.')),
      );
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter time like 35.43, 1:24.32, or 5:31.43.'),
          ),
        );
      }
    } finally {
      timeController.dispose();
      notesController.dispose();
      distanceController.dispose();
    }
  }
}

class _TrainingTabPanel extends StatelessWidget {
  const _TrainingTabPanel({
    required this.logs,
    required this.practices,
    required this.dateFormat,
    required this.onEditLog,
    required this.onDeleteLog,
    required this.onDeletePractice,
    required this.onLogSwim,
    required this.onUploadSwimPhoto,
  });

  final List<RaceLog> logs;
  final List<SwimScheduleEntry> practices;
  final DateFormat dateFormat;
  final void Function(RaceLog log) onEditLog;
  final void Function(RaceLog log) onDeleteLog;
  final void Function(SwimScheduleEntry entry) onDeletePractice;
  final VoidCallback onLogSwim;
  final VoidCallback onUploadSwimPhoto;

  @override
  Widget build(BuildContext context) {
    final hasContent = logs.isNotEmpty || practices.isNotEmpty;

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
                    Text(
                      'Training & practices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDeep,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Log swims manually or upload a workout photo. Schedule practices here.',
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: EmptyStateMessage(
                    message:
                        'No training logged yet. Tap Log swim to enter a time, '
                        'Upload photo for a workout snapshot, or Add practice to schedule.',
                  ),
                ),
              if (logs.isNotEmpty) ...[
                Text(
                  'Swim sessions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...logs.map(
                  (log) => _TrainingLogTile(
                    log: log,
                    dateFormat: dateFormat,
                    onEdit: () => onEditLog(log),
                    onDelete: () => onDeleteLog(log),
                  ),
                ),
              ],
              if (practices.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Scheduled practices',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...practices.map(
                  (entry) => ScheduleEntryTile(
                    entry: entry,
                    dateFormat: dateFormat,
                    onDelete: () => onDeletePractice(entry),
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
                FilledButton.icon(
                  onPressed: onLogSwim,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Log swim'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showScheduleEntryFormSheet(
                    context,
                    initialType: SwimScheduleEntry.typePractice,
                    allowedTypes: {SwimScheduleEntry.typePractice},
                  ),
                  icon: const Icon(Icons.pool_outlined, size: 18),
                  label: const Text('Add practice'),
                ),
                OutlinedButton.icon(
                  onPressed: onUploadSwimPhoto,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
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

class _TrainingLogTile extends StatelessWidget {
  const _TrainingLogTile({
    required this.log,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
  });

  final RaceLog log;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${log.distance} ${log.stroke} · ${log.course}'),
        subtitle: Text(
          '${dateFormat.format(log.date)} · ${log.notes?.isNotEmpty == true ? log.notes : log.event}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              SwimTime.fromSeconds(log.timeSeconds),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
