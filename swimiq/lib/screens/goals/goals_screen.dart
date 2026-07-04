import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/swim_goal.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final dateFormat = DateFormat.yMMMd();
        final goalLines = data.passportSnapshot(swimmer).goalLines;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqScreenHeader(
              title: 'Swimmer Goals',
              subtitle: 'Target times for ${data.displayName(swimmer)}',
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _stroke,
                    decoration:
                        const InputDecoration(labelText: 'Goal Stroke'),
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
                    decoration:
                        const InputDecoration(labelText: 'Goal Distance'),
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
                    decoration:
                        const InputDecoration(labelText: 'Goal Course'),
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
                  SwimIqSaveButton(
                    label: 'Save Goal',
                    isSaving: _isSaving,
                    onPressed: _saveGoal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Goal Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            if (data.goals.isEmpty)
              const EmptyStateMessage(message: 'No goals yet.')
            else
              ...goalLines.map(
                (line) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(line),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
