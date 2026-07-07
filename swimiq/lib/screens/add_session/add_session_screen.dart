import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/race_log.dart';
import '../../core/constants/swimiq_quotes.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class AddSessionScreen extends ConsumerStatefulWidget {
  const AddSessionScreen({super.key});

  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  final _strokeController =
      TextEditingController(text: AppConstants.strokes.first);
  final _courseController =
      TextEditingController(text: AppConstants.courses.first);

  int _distance = 100;
  DateTime _sessionDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _timeController.dispose();
    _notesController.dispose();
    _strokeController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _sessionDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    try {
      final timeSeconds = SwimTime.toSeconds(_timeController.text);
      final currentData = ref.read(swimmerDataProvider).value;
      final previousLogs = currentData?.raceLogs ?? [];

      final stroke = _strokeController.text.trim().isEmpty
          ? AppConstants.strokes.first
          : _strokeController.text.trim();
      final course = _courseController.text.trim().isEmpty
          ? AppConstants.courses.first
          : _courseController.text.trim();

      final isPb = SwimAnalytics.isNewPersonalBest(
        previousLogs: previousLogs,
        stroke: stroke,
        distance: _distance,
        course: course,
        timeSeconds: timeSeconds,
      );

      final log = RaceLog(
        swimmer: swimmer,
        event: '$_distance $stroke',
        distance: _distance,
        stroke: stroke,
        course: course,
        timeSeconds: timeSeconds,
        date: _sessionDate,
        notes: _notesController.text.trim(),
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).addRaceLog(log);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save session: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPb ? 'New personal best saved.' : 'Swim session saved.',
            ),
          ),
        );
        _timeController.clear();
        _notesController.clear();
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter time like 35.43, 1:24.32, or 5:31.43.',
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

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              title: 'Add Session',
              subtitle: 'Log training for ${data.displayName(swimmer)}',
              quote: SwimIqQuotes.pickFor(swimmer, SwimIqQuotes.addSession),
              stats: [
                SwimIqHeroStat('${data.raceLogs.length} sessions logged'),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _strokeController,
                    decoration: const InputDecoration(
                      labelText: 'Stroke',
                      hintText:
                          'Freestyle, Backstroke, Breaststroke, Butterfly, or IM',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '$_distance',
                    decoration: const InputDecoration(labelText: 'Distance'),
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
                    controller: _courseController,
                    decoration: const InputDecoration(
                      labelText: 'Course',
                      hintText: 'SCY, SCM, or LCM',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        SwimTime.toSeconds(value);
                      } on FormatException {
                        return 'Use 35.43 or M:SS.hh format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText:
                          'Stroke count, splits, race notes, how the swim felt, etc.',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(dateFormat.format(_sessionDate)),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwimIqSaveButton(
                    label: 'Save Swim Session',
                    isSaving: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
