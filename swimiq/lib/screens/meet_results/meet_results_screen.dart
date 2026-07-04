import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/meet_result.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class MeetResultsScreen extends ConsumerStatefulWidget {
  const MeetResultsScreen({super.key});

  @override
  ConsumerState<MeetResultsScreen> createState() => _MeetResultsScreenState();
}

class _MeetResultsScreenState extends ConsumerState<MeetResultsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetNameController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();
  final _courseController =
      TextEditingController(text: AppConstants.courses.first);

  DateTime _meetDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _meetNameController.dispose();
    _eventController.dispose();
    _timeController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _meetDate = picked);
    }
  }

  Future<void> _saveResult() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    try {
      final course = _courseController.text.trim().isEmpty
          ? AppConstants.courses.first
          : _courseController.text.trim();

      final swimTime = SwimTime.toSeconds(_timeController.text);
      final result = MeetResult(
        swimmerName: swimmer,
        meetName: _meetNameController.text.trim(),
        event: _eventController.text.trim(),
        swimTime: swimTime,
        course: course,
        meetDate: _meetDate,
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).addMeetResult(result);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save meet result: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meet result saved.')),
        );
        _meetNameController.clear();
        _eventController.clear();
        _timeController.clear();
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter result time like 35.43, 1:24.32, or 5:31.43.',
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
        final snapshot = data.passportSnapshot(swimmer);

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqScreenHeader(
              title: 'Meet Results',
              subtitle: 'Latest meet: ${snapshot.nextMeet}',
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _meetNameController,
                    decoration:
                        const InputDecoration(labelText: 'Meet Name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Meet Date'),
                    subtitle: Text(dateFormat.format(_meetDate)),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _eventController,
                    decoration: const InputDecoration(
                      labelText: 'Event',
                      hintText: 'Example: 100 Butterfly',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Result Time',
                      hintText: 'Example: 35.43 or 1:24.32',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Result time is required';
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
                    controller: _courseController,
                    decoration: const InputDecoration(
                      labelText: 'Result Course',
                      hintText: 'SCY, SCM, or LCM',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwimIqSaveButton(
                    label: 'Save Meet Result',
                    isSaving: _isSaving,
                    onPressed: _saveResult,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            if (data.meetResults.isEmpty)
              const EmptyStateMessage(message: 'No meet results yet.')
            else
              ...data.meetResults.map(
                (result) => SwimIqEventListTile(
                  title: result.event,
                  subtitle:
                      '${result.meetName} · ${result.course} · ${dateFormat.format(result.meetDate)}',
                  trailing: SwimTime.fromSeconds(result.swimTime),
                ),
              ),
          ],
        );
      },
    );
  }
}
