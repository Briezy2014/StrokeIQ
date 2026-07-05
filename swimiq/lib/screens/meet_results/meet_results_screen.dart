import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/meet_result.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

class MeetResultsScreen extends ConsumerStatefulWidget {
  const MeetResultsScreen({super.key, required this.data});

  final SwimmerData data;

  @override
  ConsumerState<MeetResultsScreen> createState() => _MeetResultsScreenState();
}

class _MeetResultsScreenState extends ConsumerState<MeetResultsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetNameController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();

  String _course = AppConstants.courses.first;
  DateTime _meetDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _meetNameController.dispose();
    _eventController.dispose();
    _timeController.dispose();
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
      final swimTime = SwimTime.toSeconds(_timeController.text);
      final result = MeetResult(
        swimmerName: swimmer,
        meetName: _meetNameController.text.trim(),
        event: _eventController.text.trim(),
        swimTime: swimTime,
        course: _course,
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

  Future<void> _deleteResult(MeetResult result) async {
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

    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(swimmerDataProvider.notifier)
        .deleteMeetResult(result.id!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Meet result deleted.')),
    );
  }

  Future<void> _editResult(MeetResult result) async {
    if (result.id == null) return;

    final meetNameController = TextEditingController(text: result.meetName);
    final eventController = TextEditingController(text: result.event);
    final timeController =
        TextEditingController(text: SwimTime.fromSeconds(result.swimTime));
    var course = result.course;
    var meetDate = result.meetDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit meet result'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: meetNameController,
                    decoration: const InputDecoration(labelText: 'Meet name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: eventController,
                    decoration: const InputDecoration(labelText: 'Event'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Result time'),
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
                    title: const Text('Meet date'),
                    subtitle: Text(DateFormat.yMMMd().format(meetDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: meetDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => meetDate = picked);
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
      meetNameController.dispose();
      eventController.dispose();
      timeController.dispose();
      return;
    }

    try {
      final swimmer = ref.read(activeSwimmerProvider)!;
      final updated = MeetResult(
        id: result.id,
        swimmerName: swimmer,
        meetName: meetNameController.text.trim(),
        event: eventController.text.trim(),
        swimTime: SwimTime.toSeconds(timeController.text),
        course: course,
        meetDate: meetDate,
      );

      final error = await ref
          .read(swimmerDataProvider.notifier)
          .updateMeetResult(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Meet result updated.')),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid result time.'),
          ),
        );
      }
    } finally {
      meetNameController.dispose();
      eventController.dispose();
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
          'Meet Results',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _meetNameController,
                decoration: const InputDecoration(labelText: 'Meet Name'),
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
              DropdownButtonFormField<String>(
                value: _course,
                decoration: const InputDecoration(labelText: 'Result Course'),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveResult,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Meet Result'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        if (widget.data.meetResults.isEmpty)
          const EmptyStateMessage(message: 'No meet results yet.')
        else
          ...widget.data.meetResults.map(
            (result) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(result.event),
                subtitle: Text(
                  '${result.meetName} · ${result.course} · '
                  '${dateFormat.format(result.meetDate)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      SwimTime.fromSeconds(result.swimTime),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editResult(result);
                        if (value == 'delete') _deleteResult(result);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
