import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/swim_goal.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key, required this.data});

  final SwimmerData data;

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();

  String _stroke = AppConstants.strokes.first;
  String _course = AppConstants.courses.first;
  int _distance = 100;
  DateTime _targetDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2045),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    try {
      final goalTime = SwimTime.toSeconds(_timeController.text);
      final goal = SwimGoal(
        swimmerName: swimmer,
        event: '$_distance $_stroke',
        goalTime: goalTime,
        course: _course,
        targetDate: _targetDate,
      );

      final error = await ref.read(swimmerDataProvider.notifier).addGoal(goal);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save goal: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal saved.')),
        );
        _timeController.clear();
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter target time like 35.43, 1:24.32, or 5:31.43.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGoal(SwimGoal goal) async {
    if (goal.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Remove goal for ${goal.event}?'),
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

    if (confirmed != true || !mounted) return;

    final error =
        await ref.read(swimmerDataProvider.notifier).deleteGoal(goal.id!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Goal deleted.')),
    );
  }

  Future<void> _editGoal(SwimGoal goal) async {
    if (goal.id == null) return;

    final parts = goal.event.split(' ');
    final distanceController = TextEditingController(
      text: parts.isNotEmpty ? parts.first : '100',
    );
    final timeController =
        TextEditingController(text: SwimTime.fromSeconds(goal.goalTime));
    var stroke = parts.length > 1 ? parts.sublist(1).join(' ') : _stroke;
    var course = goal.course;
    var targetDate = goal.targetDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: AppConstants.strokes.contains(stroke)
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
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Target time'),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Target date'),
                    subtitle: Text(DateFormat.yMMMd().format(targetDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2045),
                      );
                      if (picked != null) {
                        setDialogState(() => targetDate = picked);
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

    if (saved != true || !mounted) {
      distanceController.dispose();
      timeController.dispose();
      return;
    }

    try {
      final distance = int.parse(distanceController.text);
      final goalTime = SwimTime.toSeconds(timeController.text);
      final swimmer = ref.read(activeSwimmerProvider)!;

      final updated = SwimGoal(
        id: goal.id,
        swimmerName: swimmer,
        event: '$distance $stroke',
        goalTime: goalTime,
        course: course,
        targetDate: targetDate,
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).updateGoal(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Goal updated.')),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid target time.'),
          ),
        );
      }
    } finally {
      distanceController.dispose();
      timeController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Swimmer Goals',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _stroke,
                decoration: const InputDecoration(labelText: 'Goal Stroke'),
                items: AppConstants.strokes
                    .map((stroke) => DropdownMenuItem(
                          value: stroke,
                          child: Text(stroke),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _stroke = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '$_distance',
                decoration: const InputDecoration(labelText: 'Goal Distance'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed >= 25) {
                    setState(() => _distance = parsed);
                  }
                },
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 25) {
                    return 'Distance must be at least 25';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Target Time',
                  hintText: 'Example: 35.43 or 1:24.32',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Target time is required';
                  }
                  try {
                    SwimTime.toSeconds(value);
                  } on FormatException {
                    return 'Use 35.43 or M:SS.hh format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _course,
                decoration: const InputDecoration(labelText: 'Goal Course'),
                items: AppConstants.courses
                    .map((course) => DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _course = value);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target Date'),
                subtitle: Text(dateFormat.format(_targetDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveGoal,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Goal'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        if (widget.data.goals.isEmpty)
          const EmptyStateMessage(message: 'No goals yet.')
        else
          ...widget.data.goals.map(
            (goal) {
              final best = SwimAnalytics.bestTimeForGoal(
                goal: goal,
                raceLogs: widget.data.raceLogs,
              );
              final toGoal = SwimAnalytics.secondsToGoal(
                goal: goal,
                raceLogs: widget.data.raceLogs,
              );
              String progressText;
              if (best == null) {
                progressText = 'No swims logged for this event yet';
              } else if (toGoal != null && toGoal <= 0) {
                progressText = 'Goal achieved! PB: ${SwimTime.fromSeconds(best)}';
              } else if (toGoal != null) {
                progressText =
                    'Current: ${SwimTime.fromSeconds(best)} · '
                    '${SwimTime.fromSeconds(toGoal)} to go';
              } else {
                progressText = 'Current: ${SwimTime.fromSeconds(best)}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(goal.event),
                  subtitle: Text(
                    '${goal.course} · Target: ${dateFormat.format(goal.targetDate)}\n'
                    '$progressText',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        SwimTime.fromSeconds(goal.goalTime),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _editGoal(goal);
                          if (value == 'delete') _deleteGoal(goal);
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
            },
          ),
      ],
    );
  }
}
