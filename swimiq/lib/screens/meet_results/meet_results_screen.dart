import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swim_event_parser.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/meet_result.dart';
import '../../data/models/scheduled_meet.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../providers/meet_schedule_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swim_form_fields.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/meet_schedule_section.dart';

class MeetResultsScreen extends ConsumerStatefulWidget {
  const MeetResultsScreen({super.key});

  @override
  ConsumerState<MeetResultsScreen> createState() => _MeetResultsScreenState();
}

class _MeetResultsScreenState extends ConsumerState<MeetResultsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _formSectionKey = GlobalKey();
  final _meetNameController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();
  String _course = AppConstants.courses.first;

  DateTime _meetDate = DateTime.now();
  bool _isSaving = false;
  ScheduledMeet? _loggingMeet;

  @override
  void dispose() {
    _scrollController.dispose();
    _meetNameController.dispose();
    _eventController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _beginLoggingForMeet(ScheduledMeet meet) {
    setState(() {
      _loggingMeet = meet;
      _meetNameController.text = meet.name;
      _meetDate = meet.startDate;
      final course = meet.course?.trim().toUpperCase();
      if (course != null &&
          course.isNotEmpty &&
          AppConstants.courses.contains(course)) {
        _course = course;
      }
      _eventController.clear();
      _timeController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _formSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
      _eventController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _eventController.text.length,
      );
      FocusScope.of(this.context).requestFocus(FocusNode());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logging times for ${meet.name}. Add each event and save — '
          'meet name and date stay filled.',
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
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
      final course = _course;

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
        if (_loggingMeet != null) {
          _eventController.clear();
          _timeController.clear();
        } else {
          _meetNameController.clear();
          _eventController.clear();
          _timeController.clear();
        }
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

  Future<void> _editResult(MeetResult result) async {
    if (result.id == null) return;

    final meetController = TextEditingController(text: result.meetName);
    final eventController = TextEditingController(text: result.event);
    final timeController =
        TextEditingController(text: SwimTime.fromSeconds(result.swimTime));
    final courseController = TextEditingController(text: result.course);
    var meetDate = result.meetDate;
    final dateFormat = DateFormat.yMMMd();

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
                    controller: meetController,
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
                  TextField(
                    controller: courseController,
                    decoration: const InputDecoration(labelText: 'Course'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Meet date'),
                    subtitle: Text(dateFormat.format(meetDate)),
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
      meetController.dispose();
      eventController.dispose();
      timeController.dispose();
      courseController.dispose();
      return;
    }

    try {
      final updated = MeetResult(
        id: result.id,
        swimmerName: result.swimmerName,
        meetName: meetController.text.trim(),
        event: eventController.text.trim(),
        swimTime: SwimTime.toSeconds(timeController.text),
        course: courseController.text.trim(),
        meetDate: meetDate,
        notes: result.notes,
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
          const SnackBar(content: Text('Enter a valid result time.')),
        );
      }
    } finally {
      meetController.dispose();
      eventController.dispose();
      timeController.dispose();
      courseController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final dateFormat = DateFormat.yMMMd();
        final attendingMeets = ref.watch(attendingMeetsProvider);
        final snapshot = data.passportSnapshot(
          swimmer,
          attendingMeets: attendingMeets,
        );

        return ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqScreenHeader(
              title: 'Meet Results',
              subtitle: 'Upcoming: ${snapshot.upcomingMeet} · latest result: '
                  '${snapshot.lastMeetResult}',
            ),
            const SizedBox(height: 16),
            MeetScheduleSection(onLogResults: _beginLoggingForMeet),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _formSectionKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loggingMeet == null
                        ? 'Log a meet result'
                        : 'Log times for ${_loggingMeet!.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_loggingMeet != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(_meetDate)} · $_course · '
                      'Add each event, then save. Meet details stay filled.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
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
                  SwimCourseDropdown(
                    value: _course,
                    label: 'Result Course',
                    onChanged: (value) => setState(() => _course = value),
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
                (result) {
                  final parts = SwimEventParser.parse(result.event);
                  final cut = parts == null
                      ? null
                      : MotivationalCut.labelForSwim(
                          catalog: data.motivationalStandards,
                          profile: data.profile,
                          stroke: parts.stroke,
                          distance: parts.distance,
                          course: result.course,
                          timeSeconds: result.swimTime,
                        );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(result.event),
                      subtitle: Text(
                        '${result.meetName} · ${result.course} · '
                        '${dateFormat.format(result.meetDate)} · '
                        '${cut ?? 'Below B'} cut',
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
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
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
      },
    );
  }
}
