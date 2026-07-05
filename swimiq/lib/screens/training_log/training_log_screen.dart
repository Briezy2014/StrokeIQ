import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

/// Training log with list, edit, and delete — Milestone 3 CRUD.
class TrainingLogScreen extends ConsumerWidget {
  const TrainingLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(swimmerDataProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load training log: $error')),
      data: (data) {
        if (data == null) {
          return const Center(child: Text('No swimmer data loaded.'));
        }

        final logs = data.raceLogs;
        final dateFormat = DateFormat.yMMMd();

        return logs.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    EmptyStateMessage(
                      message:
                          'No swim sessions yet. Use the Add tab to log your first training swim.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Training Log',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      );
                    }

                    final log = logs[index - 1];
                    return _TrainingLogTile(
                      log: log,
                      dateFormat: dateFormat,
                      onEdit: () => _editLog(context, ref, log),
                      onDelete: () => _deleteLog(context, ref, log),
                    );
                  },
                );
      },
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
      SnackBar(
        content: Text(
          error ?? 'Swim session deleted.',
        ),
      ),
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
                    value: stroke,
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
                    value: course,
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
                    subtitle: Text(DateFormat.yMMMd().format(sessionDate)),
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

    if (saved != true || !context.mounted) return;

    try {
      final timeSeconds = SwimTime.toSeconds(timeController.text);
      final distance = int.parse(distanceController.text);
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
        SnackBar(
          content: Text(error ?? 'Swim session updated.'),
        ),
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
