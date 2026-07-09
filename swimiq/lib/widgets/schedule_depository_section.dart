import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/image_pick_utils.dart';
import '../core/theme/app_theme.dart';
import '../data/models/swim_schedule_entry.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../widgets/swimiq_ui.dart';

/// Shared form + list for practice/meet/race schedule uploads.
class ScheduleDepositorySection extends ConsumerStatefulWidget {
  const ScheduleDepositorySection({
    super.key,
    this.compact = false,
    this.onOpenRaceIntelligence,
  });

  final bool compact;
  final VoidCallback? onOpenRaceIntelligence;

  @override
  ConsumerState<ScheduleDepositorySection> createState() =>
      _ScheduleDepositorySectionState();
}

class _ScheduleDepositorySectionState
    extends ConsumerState<ScheduleDepositorySection> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _eventsController = TextEditingController();
  final _notesController = TextEditingController();

  String _scheduleType = SwimScheduleEntry.typeMeet;
  DateTime _scheduleDate = DateTime.now();
  bool _isSaving = false;
  bool _showForm = false;
  Uint8List? _schedulePhotoBytes;
  String? _schedulePhotoName;
  final _saveSectionKey = GlobalKey();

  @override
  void dispose() {
    _titleController.dispose();
    _startTimeController.dispose();
    _locationController.dispose();
    _eventsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  void _openForm(String type) {
    setState(() {
      _scheduleType = type;
      _showForm = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _saveSectionKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.85,
        );
      }
    });
  }

  Future<void> _pickSchedulePhoto() async {
    final picked = await pickImageFromUserChoice(context);
    if (picked == null) return;
    setState(() {
      _schedulePhotoBytes = picked.bytes;
      _schedulePhotoName = picked.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    var notes = _optional(_notesController.text) ?? '';
    if (_schedulePhotoBytes != null) {
      try {
        final url = await ref.read(profilePhotoServiceProvider).uploadSchedulePhoto(
              swimmer: swimmer,
              fileName: _schedulePhotoName ?? 'schedule.jpg',
              bytes: _schedulePhotoBytes!,
            );
        notes = notes.isEmpty ? 'Schedule photo: $url' : '$notes\nSchedule photo: $url';
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not upload schedule photo.')),
          );
        }
      }
    }

    final entry = SwimScheduleEntry(
      swimmerName: swimmer,
      scheduleType: _scheduleType,
      title: _titleController.text.trim(),
      scheduleDate: _scheduleDate,
      startTime: _optional(_startTimeController.text),
      location: _optional(_locationController.text),
      eventsLine: _optional(_eventsController.text),
      notes: notes.isEmpty ? null : notes,
    );

    final error =
        await ref.read(swimmerDataProvider.notifier).addSchedule(entry);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (error == null) {
        _showForm = false;
        _titleController.clear();
        _startTimeController.clear();
        _locationController.clear();
        _eventsController.clear();
        _notesController.clear();
        _schedulePhotoBytes = null;
        _schedulePhotoName = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              '${_typeLabel(_scheduleType)} saved. '
              'You can add another or switch tabs.',
        ),
        backgroundColor: error != null ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _deleteEntry(SwimScheduleEntry entry) async {
    if (entry.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove schedule entry?'),
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
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(swimmerDataProvider.notifier)
        .deleteSchedule(entry.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Schedule removed.')),
    );
  }

  String? _optional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(swimmerDataProvider).value;
    final schedules = data?.schedules ?? const <SwimScheduleEntry>[];
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.compact
                          ? 'Quick schedule upload'
                          : 'Schedule & meet depot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDeep,
                          ),
                    ),
                  ),
                  if (widget.onOpenRaceIntelligence != null)
                    FilledButton.tonalIcon(
                      onPressed: widget.onOpenRaceIntelligence,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Race plan'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Add meets, practices, race results, and schedule photos. '
                'Tap a button below, fill the form, then tap Save.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _openForm(SwimScheduleEntry.typeMeet),
              icon: const Icon(Icons.emoji_events_outlined, size: 18),
              label: const Text('Add meet'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openForm(SwimScheduleEntry.typePractice),
              icon: const Icon(Icons.pool_outlined, size: 18),
              label: const Text('Add practice'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openForm(SwimScheduleEntry.typeRace),
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: const Text('Add race result'),
            ),
          ],
        ),
        if (_showForm) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New ${_typeLabel(_scheduleType)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: SwimScheduleEntry.typeMeet,
                          label: Text('Meet'),
                        ),
                        ButtonSegment(
                          value: SwimScheduleEntry.typePractice,
                          label: Text('Practice'),
                        ),
                        ButtonSegment(
                          value: SwimScheduleEntry.typeRace,
                          label: Text('Result'),
                        ),
                      ],
                      selected: {_scheduleType},
                      onSelectionChanged: (values) {
                        setState(() => _scheduleType = values.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _titleFieldLabel(),
                        hintText: _titleFieldHint(),
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(dateFormat.format(_scheduleDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                    ),
                    if (_scheduleType != SwimScheduleEntry.typeRace) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Start / warm-up time (optional)',
                          hintText: '9:30 AM warm-up',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Pool / location (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _eventsController,
                      decoration: InputDecoration(
                        labelText: _eventsFieldLabel(),
                        hintText: _eventsFieldHint(),
                      ),
                      maxLines: 4,
                      validator: _scheduleType == SwimScheduleEntry.typeRace
                          ? (value) => value?.trim().isEmpty == true
                              ? 'Add at least one event and result time'
                              : null
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: _notesFieldHint(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickSchedulePhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(
                        _schedulePhotoName == null
                            ? 'Attach schedule photo'
                            : 'Change photo (${_schedulePhotoName!})',
                      ),
                    ),
                    if (_schedulePhotoBytes != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _schedulePhotoBytes!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() {
                                    _schedulePhotoBytes = null;
                                    _schedulePhotoName = null;
                                  }),
                          child: const Text('Remove photo'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    KeyedSubtree(
                      key: _saveSectionKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwimIqSaveButton(
                            label: 'Save',
                            isSaving: _isSaving,
                            onPressed: _save,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => setState(() => _showForm = false),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (schedules.isEmpty)
          Text(
            'No schedules saved yet. Add a meet or practice to unlock Race Intelligence.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.65),
                ),
          )
        else
          ...schedules.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_iconForType(entry.scheduleType)),
                title: Text(entry.title),
                subtitle: Text(
                  '${entry.typeLabel} · ${dateFormat.format(entry.scheduleDate)}'
                  '${entry.startTime != null ? ' · ${entry.startTime}' : ''}'
                  '${entry.eventsLine != null ? '\n${entry.eventsLine}' : ''}'
                  '${entry.notes != null ? '\n${entry.notes}' : ''}',
                ),
                isThreeLine: entry.eventsLine != null || entry.notes != null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteEntry(entry),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case SwimScheduleEntry.typeMeet:
        return 'meet';
      case SwimScheduleEntry.typeRace:
        return 'race result';
      default:
        return 'practice';
    }
  }

  String _titleFieldLabel() {
    switch (_scheduleType) {
      case SwimScheduleEntry.typePractice:
        return 'Practice name';
      case SwimScheduleEntry.typeRace:
        return 'Meet or session name';
      default:
        return 'Meet name';
    }
  }

  String _titleFieldHint() {
    switch (_scheduleType) {
      case SwimScheduleEntry.typePractice:
        return 'Saturday AM aerobic';
      case SwimScheduleEntry.typeRace:
        return 'Central Regional Champs';
      default:
        return 'Central Regional Champs';
    }
  }

  String _eventsFieldLabel() {
    switch (_scheduleType) {
      case SwimScheduleEntry.typeRace:
        return 'Events & result times';
      case SwimScheduleEntry.typeMeet:
        return 'Events she is swimming (optional)';
      default:
        return 'Workout focus (optional)';
    }
  }

  String _eventsFieldHint() {
    switch (_scheduleType) {
      case SwimScheduleEntry.typeRace:
        return '50 Fly — 28.45\n100 Free — 1:02.34\n(one event + time per line)';
      case SwimScheduleEntry.typeMeet:
        return '50 Fly, 100 IM, 200 Free\n(one per line)';
      default:
        return 'IM focus, kick set, etc.';
    }
  }

  String _notesFieldHint() {
    if (_scheduleType == SwimScheduleEntry.typeRace) {
      return 'Finals notes, splits, or coach feedback';
    }
    return 'Heat sheet, lane, or coach notes';
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case SwimScheduleEntry.typeMeet:
        return Icons.emoji_events_outlined;
      case SwimScheduleEntry.typeRace:
        return Icons.timer_outlined;
      default:
        return Icons.pool_outlined;
    }
  }
}
