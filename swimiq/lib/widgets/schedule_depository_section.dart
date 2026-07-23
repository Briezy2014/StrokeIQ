import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/swimiq_camera_capture.dart';
import '../core/utils/upcoming_meet_builder.dart';
import '../core/theme/app_theme.dart';
import '../data/models/swim_schedule_entry.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import 'swimiq_ui.dart';

Future<void> showScheduleEntryFormSheet(
  BuildContext context, {
  required String initialType,
  Set<String>? allowedTypes,
  bool startWithPhotoPicker = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ScheduleEntryFormSheet(
        initialType: initialType,
        allowedTypes: allowedTypes,
        startWithPhotoPicker: startWithPhotoPicker,
      ),
    ),
  );
}

/// Shared list + bottom actions for practice/meet/race schedule uploads.
class ScheduleDepositorySection extends ConsumerWidget {
  const ScheduleDepositorySection({
    super.key,
    required this.showTypes,
    required this.addTypes,
    this.headerTitle = 'Schedule & meet depot',
    this.headerSubtitle =
        'Saved entries appear here. Use the buttons below to add a new one.',
    this.emptyMessage = 'Nothing saved yet. Tap a button below to add one.',
    this.compact = false,
    this.onOpenRaceIntelligence,
  });

  final Set<String> showTypes;
  final Set<String> addTypes;
  final String headerTitle;
  final String headerSubtitle;
  final String emptyMessage;
  final bool compact;
  final VoidCallback? onOpenRaceIntelligence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(swimmerDataProvider).value;
    final schedules = (data?.schedules ?? const <SwimScheduleEntry>[])
        .where((entry) => showTypes.contains(entry.scheduleType))
        .toList();
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
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
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            compact ? 'Schedule depot' : headerTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDeep,
                                ),
                          ),
                        ),
                        if (onOpenRaceIntelligence != null)
                          FilledButton.tonalIcon(
                            onPressed: onOpenRaceIntelligence,
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: const Text('Race plan'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      headerSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textDark.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (schedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.65),
                        ),
                  ),
                )
              else
                ...schedules.map(
                  (entry) => ScheduleEntryTile(
                    entry: entry,
                    dateFormat: dateFormat,
                    onDelete: () => _deleteEntry(context, ref, entry),
                  ),
                ),
            ],
          ),
        ),
        if (addTypes.isNotEmpty)
          ScheduleDepositoryActionBar(
            addTypes: addTypes,
            onAdd: (type, {photoFirst = false}) => showScheduleEntryFormSheet(
              context,
              initialType: type,
              allowedTypes: addTypes,
              startWithPhotoPicker: photoFirst,
            ),
          ),
      ],
    );
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    SwimScheduleEntry entry,
  ) async {
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
    if (confirmed != true || !context.mounted) return;

    final error =
        await ref.read(swimmerDataProvider.notifier).deleteSchedule(entry.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Schedule removed.')),
    );
  }

  static IconData iconForScheduleType(String type) {
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

class ScheduleEntryTile extends StatelessWidget {
  const ScheduleEntryTile({
    super.key,
    required this.entry,
    required this.dateFormat,
    required this.onDelete,
  });

  final SwimScheduleEntry entry;
  final DateFormat dateFormat;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(ScheduleDepositorySection.iconForScheduleType(
          entry.scheduleType,
        )),
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
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class ScheduleDepositoryActionBar extends StatelessWidget {
  const ScheduleDepositoryActionBar({
    super.key,
    required this.addTypes,
    required this.onAdd,
    this.showUploadPhoto = true,
  });

  final Set<String> addTypes;
  final void Function(String type, {bool photoFirst}) onAdd;
  final bool showUploadPhoto;

  String get _defaultType {
    if (addTypes.contains(SwimScheduleEntry.typeMeet)) {
      return SwimScheduleEntry.typeMeet;
    }
    if (addTypes.contains(SwimScheduleEntry.typePractice)) {
      return SwimScheduleEntry.typePractice;
    }
    return addTypes.first;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (addTypes.contains(SwimScheduleEntry.typeMeet))
              FilledButton.icon(
                onPressed: () => onAdd(SwimScheduleEntry.typeMeet),
                icon: const Icon(Icons.emoji_events_outlined, size: 18),
                label: const Text('Add meet'),
              ),
            if (addTypes.contains(SwimScheduleEntry.typePractice))
              FilledButton.icon(
                onPressed: () => onAdd(SwimScheduleEntry.typePractice),
                icon: const Icon(Icons.pool_outlined, size: 18),
                label: const Text('Add practice'),
              ),
            if (addTypes.contains(SwimScheduleEntry.typeRace))
              FilledButton.tonalIcon(
                onPressed: () => onAdd(SwimScheduleEntry.typeRace),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('Add result'),
              ),
            if (showUploadPhoto)
              OutlinedButton.icon(
                onPressed: () => onAdd(_defaultType, photoFirst: true),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Upload photo'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEntryFormSheet extends ConsumerStatefulWidget {
  const _ScheduleEntryFormSheet({
    required this.initialType,
    this.allowedTypes,
    this.startWithPhotoPicker = false,
  });

  final String initialType;
  final Set<String>? allowedTypes;
  final bool startWithPhotoPicker;

  @override
  ConsumerState<_ScheduleEntryFormSheet> createState() =>
      _ScheduleEntryFormSheetState();
}

class _ScheduleEntryFormSheetState
    extends ConsumerState<_ScheduleEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _eventsController = TextEditingController();
  final _notesController = TextEditingController();
  final List<TextEditingController> _dayStartTimeControllers = [];
  final List<TextEditingController> _dayEventsControllers = [];

  late String _scheduleType;
  DateTime _scheduleDate = DateTime.now();
  int _meetDayCount = 1;
  bool _isSaving = false;
  Uint8List? _schedulePhotoBytes;
  String? _schedulePhotoName;

  bool get _isUpcomingMeet => _scheduleType == SwimScheduleEntry.typeMeet;

  @override
  void initState() {
    super.initState();
    final allowed = widget.allowedTypes;
    if (allowed != null &&
        allowed.isNotEmpty &&
        !allowed.contains(widget.initialType)) {
      _scheduleType = allowed.first;
    } else {
      _scheduleType = widget.initialType;
    }
    _syncMeetDayControllers(1);
    if (widget.startWithPhotoPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickSchedulePhotoFromFiles());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startTimeController.dispose();
    _locationController.dispose();
    _eventsController.dispose();
    _notesController.dispose();
    for (final controller in _dayStartTimeControllers) {
      controller.dispose();
    }
    for (final controller in _dayEventsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncMeetDayControllers(int dayCount) {
    final count = dayCount.clamp(1, 5);
    while (_dayStartTimeControllers.length < count) {
      _dayStartTimeControllers.add(TextEditingController());
      _dayEventsControllers.add(TextEditingController());
    }
    while (_dayStartTimeControllers.length > count) {
      _dayStartTimeControllers.removeLast().dispose();
      _dayEventsControllers.removeLast().dispose();
    }
    _meetDayCount = count;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _isUpcomingMeet ? 'Meet start date' : 'Select date',
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  Future<void> _pickStartTime({required TextEditingController controller}) async {
    final initial = _parseTimeOfDay(controller.text) ??
        const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Warm-up / session start',
    );
    if (picked == null || !mounted) return;
    setState(() => controller.text = _formatTimeOfDay(picked));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$',
    ).firstMatch(text);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final meridian = match.group(3)?.toUpperCase();
    if (meridian == 'PM' && hour < 12) hour += 12;
    if (meridian == 'AM' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickSchedulePhotoFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _schedulePhotoBytes = file.bytes;
      _schedulePhotoName = file.name;
    });
  }

  Future<void> _takeSchedulePhoto() async {
    final photo = await captureSwimIqPhoto(context);
    if (photo == null || !mounted) return;
    setState(() {
      _schedulePhotoBytes = photo.bytes;
      _schedulePhotoName = photo.fileName;
    });
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    final swimmer = ref.read(activeSwimmerProvider)?.trim();
    if (swimmer == null || swimmer.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a swimmer before saving a meet.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    String? error;
    var savedCount = 0;

    try {
      var notes = _optional(_notesController.text) ?? '';
      if (_schedulePhotoBytes != null) {
        try {
          final url =
              await ref.read(profilePhotoServiceProvider).uploadSchedulePhoto(
                    swimmer: swimmer,
                    fileName: _schedulePhotoName ?? 'schedule.jpg',
                    bytes: _schedulePhotoBytes!,
                  );
          notes = notes.isEmpty
              ? 'Schedule photo: $url'
              : '$notes\nSchedule photo: $url';
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not upload schedule photo.')),
            );
          }
        }
      }

      final List<SwimScheduleEntry> entries;
      if (_isUpcomingMeet) {
        // Keep controllers and day count in sync before reading.
        _syncMeetDayControllers(_meetDayCount);
        entries = buildUpcomingMeetEntries(
          swimmerName: swimmer,
          title: _titleController.text.trim(),
          location: _optional(_locationController.text),
          notes: notes.isEmpty ? null : notes,
          days: [
            for (var i = 0; i < _meetDayCount; i++)
              UpcomingMeetDayInput(
                date: _scheduleDate.add(Duration(days: i)),
                startTime: i < _dayStartTimeControllers.length
                    ? _optional(_dayStartTimeControllers[i].text)
                    : null,
                eventsLine: i < _dayEventsControllers.length
                    ? _optional(_dayEventsControllers[i].text)
                    : null,
              ),
          ],
        );
      } else {
        entries = [
          SwimScheduleEntry(
            swimmerName: swimmer,
            scheduleType: _scheduleType,
            title: _titleController.text.trim(),
            scheduleDate: _scheduleDate,
            startTime: _optional(_startTimeController.text),
            location: _optional(_locationController.text),
            eventsLine: _optional(_eventsController.text),
            notes: notes.isEmpty ? null : notes,
          ),
        ];
      }

      savedCount = entries.length;
      error =
          await ref.read(swimmerDataProvider.notifier).addSchedules(entries);
    } catch (err) {
      error = err.toString().contains('Null check operator')
          ? 'Could not save this meet — check the meet name, days, and times, then try again.'
          : 'Could not save this meet. Please try again.';
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final dayPart = savedCount > 1 ? ' ($savedCount days)' : '';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${_typeLabel(_scheduleType)}$dayPart saved. '
          'Race Intelligence will use your next meet.',
        ),
      ),
    );
  }

  String? _optional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final allowed = widget.allowedTypes ??
        {
          SwimScheduleEntry.typeMeet,
          SwimScheduleEntry.typePractice,
          SwimScheduleEntry.typeRace,
        };
    final showTypePicker = allowed.length > 1;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New ${_typeLabel(_scheduleType)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            if (showTypePicker) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  if (allowed.contains(SwimScheduleEntry.typeMeet))
                    const ButtonSegment(
                      value: SwimScheduleEntry.typeMeet,
                      label: Text('Meet'),
                    ),
                  if (allowed.contains(SwimScheduleEntry.typePractice))
                    const ButtonSegment(
                      value: SwimScheduleEntry.typePractice,
                      label: Text('Practice'),
                    ),
                  if (allowed.contains(SwimScheduleEntry.typeRace))
                    const ButtonSegment(
                      value: SwimScheduleEntry.typeRace,
                      label: Text('Result'),
                    ),
                ],
                selected: {allowed.contains(_scheduleType) ? _scheduleType : allowed.first},
                onSelectionChanged: (values) {
                  setState(() => _scheduleType = values.first);
                },
              ),
            ],
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
              title: Text(_isUpcomingMeet ? 'Meet start date' : 'Date'),
              subtitle: Text(dateFormat.format(_scheduleDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            if (_isUpcomingMeet) ...[
              const SizedBox(height: 8),
              Text(
                'How many days?',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final days in const [1, 2, 3, 4, 5])
                    ChoiceChip(
                      label: Text(days == 1 ? '1 day' : '$days days'),
                      selected: _meetDayCount == days,
                      onSelected: (_) {
                        setState(() => _syncMeetDayControllers(days));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Pool / location (optional)',
                ),
              ),
              for (var i = 0; i < _meetDayCount; i++) ...[
                const SizedBox(height: 16),
                Text(
                  _meetDayCount == 1
                      ? 'Meet day details'
                      : 'Day ${i + 1} · ${dateFormat.format(_scheduleDate.add(Duration(days: i)))}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dayStartTimeControllers[i],
                  readOnly: true,
                  onTap: () => _pickStartTime(
                    controller: _dayStartTimeControllers[i],
                  ),
                  decoration: InputDecoration(
                    labelText: 'Start / warm-up time',
                    hintText: 'Tap to pick time',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () => _pickStartTime(
                        controller: _dayStartTimeControllers[i],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dayEventsControllers[i],
                  decoration: const InputDecoration(
                    labelText: 'Events that day',
                    hintText: '50 Fly, 100 IM, 200 Free\n(one per line)',
                  ),
                  maxLines: 3,
                ),
              ],
            ] else ...[
              if (_scheduleType != SwimScheduleEntry.typeRace) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _startTimeController,
                  readOnly: true,
                  onTap: () =>
                      _pickStartTime(controller: _startTimeController),
                  decoration: InputDecoration(
                    labelText: 'Start / warm-up time (optional)',
                    hintText: 'Tap to pick time',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () =>
                          _pickStartTime(controller: _startTimeController),
                    ),
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
            ],
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _takeSchedulePhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickSchedulePhotoFromFiles,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Upload'),
                  ),
                ),
              ],
            ),
            if (_schedulePhotoName != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _schedulePhotoName!,
                  style: Theme.of(context).textTheme.labelSmall,
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
            SwimIqSaveButton(
              label: 'Save',
              isSaving: _isSaving,
              onPressed: _save,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
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
}
