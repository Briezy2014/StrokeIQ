import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
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

  late String _scheduleType;
  DateTime _scheduleDate = DateTime.now();
  bool _isSaving = false;
  Uint8List? _schedulePhotoBytes;
  String? _schedulePhotoName;

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
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    setState(() {
      _schedulePhotoBytes = bytes;
      _schedulePhotoName = photo.name;
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
        final url =
            await ref.read(profilePhotoServiceProvider).uploadSchedulePhoto(
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
    setState(() => _isSaving = false);

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
    if (mounted) Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${_typeLabel(_scheduleType)} saved. '
          'You can add another or switch tabs.',
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
