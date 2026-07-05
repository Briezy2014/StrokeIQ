import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/swimiq_theme.dart';
import '../../data/repositories/race_log_repository.dart';
import '../../domain/models/race_log.dart';
import '../../domain/utils/personal_best_utils.dart';
import '../../domain/utils/swim_time_utils.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/swimmer_providers.dart';

class AddSessionScreen extends ConsumerStatefulWidget {
  const AddSessionScreen({super.key});

  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();

  String _stroke = AppConstants.strokes.first;
  String _course = AppConstants.courses.first;
  int _distance = 100;
  DateTime _sessionDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmerKey = ref.read(activeSwimmerKeyProvider);
    if (swimmerKey == null) return;

    setState(() => _isSaving = true);

    try {
      final timeSeconds = SwimTimeUtils.swimTimeToSeconds(_timeController.text);
      final existingLogs = await ref.read(raceLogsProvider.future);
      final entries = existingLogs.map((log) => log.toEntry()).toList();

      final isPb = PersonalBestUtils.isNewPersonalBest(
        previousLogs: entries,
        stroke: _stroke,
        distance: _distance,
        course: _course,
        timeSeconds: timeSeconds,
      );

      final log = RaceLog(
        swimmer: swimmerKey,
        stroke: _stroke,
        distance: _distance,
        course: _course,
        timeSeconds: timeSeconds,
        event: '$_distance $_stroke',
        date: _sessionDate,
        notes: _notesController.text.trim(),
      );

      await ref.read(raceLogRepositoryProvider).insert(log);
      ref.invalidate(raceLogsProvider);
      ref.invalidate(dashboardSummaryProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPb ? 'New personal best saved!' : 'Swim session saved.',
          ),
        ),
      );
      context.pop();
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save session: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Swim Session'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter times like 35.43, 1:24.32, or 5:31.43.',
                  style: TextStyle(color: SwimIQColors.textSecondary),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _stroke,
                  decoration: const InputDecoration(labelText: 'Stroke'),
                  items: [
                    for (final stroke in AppConstants.strokes)
                      DropdownMenuItem(value: stroke, child: Text(stroke)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _stroke = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _distance,
                  decoration: const InputDecoration(labelText: 'Distance'),
                  items: [
                    for (var distance = 25; distance <= 1650; distance += 25)
                      DropdownMenuItem(
                        value: distance,
                        child: Text('$distance'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _distance = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _course,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: [
                    for (final course in AppConstants.courses)
                      DropdownMenuItem(value: course, child: Text(course)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _course = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: 'Example: 35.43 or 1:24.32',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Time is required';
                    }
                    try {
                      SwimTimeUtils.swimTimeToSeconds(value);
                    } on FormatException catch (error) {
                      return error.message;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(DateFormat.yMMMd().format(_sessionDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: _sessionDate,
                    );
                    if (picked != null) {
                      setState(() => _sessionDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Swim Session'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
