import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/race_log.dart';
import '../providers/app_providers.dart';
import '../utils/personal_bests.dart';
import '../utils/swim_time.dart';

class AddSessionScreen extends ConsumerStatefulWidget {
  const AddSessionScreen({super.key});

  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();

  static const _strokes = [
    'Freestyle',
    'Backstroke',
    'Breaststroke',
    'Butterfly',
    'IM',
  ];
  static const _courses = ['SCY', 'SCM', 'LCM'];

  String _stroke = _strokes.first;
  String _course = _courses.first;
  int _distance = 100;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _saving = true);

    try {
      final timeSeconds = SwimTime.toSeconds(_timeController.text);
      final data = await ref.read(swimmerDataProvider.future);
      final isPb = PersonalBests.isNewPersonalBest(
        previousLogs: data.raceLogs,
        stroke: _stroke,
        distance: _distance,
        course: _course,
        timeSeconds: timeSeconds,
      );

      final log = RaceLog(
        swimmer: swimmer,
        event: '$_distance $_stroke',
        distance: _distance,
        stroke: _stroke,
        course: _course,
        timeSeconds: timeSeconds,
        date: DateFormat('yyyy-MM-dd').format(_date),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref.read(supabaseServiceProvider).insertRaceLog(log);
      refreshData(ref);

      if (!mounted) return;

      _timeController.clear();
      _notesController.clear();
      setState(() {
        _distance = 100;
        _date = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPb ? '🔥 New Personal Best!' : 'Swim session saved.',
          ),
          backgroundColor: isPb ? const Color(0xFFFF7675) : SwimIQTheme.primaryBlue,
        ),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter time like 35.43, 1:24.32, or 5:31.43.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SwimIQTheme.softBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SwimIQTheme.borderBlue),
              ),
              child: Text(
                'Enter times like 35.43, 1:24.32, or 5:31.43.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _stroke,
              decoration: const InputDecoration(labelText: 'Stroke'),
              items: _strokes
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _stroke = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _course,
              decoration: const InputDecoration(labelText: 'Course'),
              items: _courses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _course = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '$_distance',
              decoration: const InputDecoration(
                labelText: 'Distance',
                suffixText: 'yards/meters',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final parsed = int.tryParse(v ?? '');
                if (parsed == null || parsed < 25) {
                  return 'Enter a distance of at least 25';
                }
                return null;
              },
              onSaved: (_) {},
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) _distance = parsed;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'Example: 35.43 or 1:24.32',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Time is required';
                try {
                  SwimTime.toSeconds(v);
                  return null;
                } catch (_) {
                  return 'Use 35.43 or 1:24.32 format';
                }
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateFormat('MMM d, yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Stroke count, splits, how the swim felt...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save Swim Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
