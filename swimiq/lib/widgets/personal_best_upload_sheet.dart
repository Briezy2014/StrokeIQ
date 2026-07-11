import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/swim_event_options.dart';
import '../core/utils/swimiq_camera_capture.dart';
import '../data/models/meet_result.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import 'swim_time_entry_fields.dart';
import 'swimiq_ui.dart';

Future<void> showPersonalBestUploadSheet(
  BuildContext context, {
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
      child: PersonalBestUploadSheet(
        startWithPhotoPicker: startWithPhotoPicker,
      ),
    ),
  );
}

class _BestTimeRow {
  _BestTimeRow() : timeKey = GlobalKey<SwimTimeEntryFieldsState>();

  SwimEventOption? event;
  final GlobalKey<SwimTimeEntryFieldsState> timeKey;
}

class PersonalBestUploadSheet extends ConsumerStatefulWidget {
  const PersonalBestUploadSheet({super.key, this.startWithPhotoPicker = false});

  final bool startWithPhotoPicker;

  @override
  ConsumerState<PersonalBestUploadSheet> createState() =>
      _PersonalBestUploadSheetState();
}

class _PersonalBestUploadSheetState
    extends ConsumerState<PersonalBestUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _rows = <_BestTimeRow>[_BestTimeRow()];

  DateTime _achievedDate = DateTime.now();
  String _course = AppConstants.courses.first;
  bool _isSaving = false;
  Uint8List? _photoBytes;
  String? _photoName;

  static const _uploadSourceLabel = 'Uploaded best times';

  @override
  void initState() {
    super.initState();
    if (widget.startWithPhotoPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhotoFromFiles());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<SwimEventOption> _eventOptions() {
    final data = ref.read(swimmerDataProvider).value;
    if (data == null) return const [];
    return SwimEventOptions.forProfile(
      catalog: data.motivationalStandards,
      profile: data.profile,
      course: _course,
    );
  }

  SwimEventOption? _matchingSelection(
    List<SwimEventOption> options,
    SwimEventOption? selected,
  ) {
    if (options.isEmpty) return null;
    if (selected == null) return options.first;
    for (final option in options) {
      if (option.distance == selected.distance &&
          option.stroke == selected.stroke &&
          option.course == selected.course) {
        return option;
      }
    }
    return options.first;
  }

  void _addRow() {
    setState(() => _rows.add(_BestTimeRow()));
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() => _rows.removeAt(index));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _achievedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _achievedDate = picked);
  }

  Future<void> _pickPhotoFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _photoBytes = file.bytes;
      _photoName = file.name;
    });
  }

  Future<void> _takePhoto() async {
    final photo = await captureSwimIqPhoto(context);
    if (photo == null || !mounted) return;
    setState(() {
      _photoBytes = photo.bytes;
      _photoName = photo.fileName;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final eventOptions = _eventOptions();
    if (eventOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add birthday and gender in the Athlete Passport to load events.',
          ),
        ),
      );
      return;
    }

    final parsedRows = <({SwimEventOption event, double timeSeconds})>[];
    for (final row in _rows) {
      final timeError = row.timeKey.currentState?.validate();
      if (timeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(timeError)),
        );
        return;
      }

      final swimTime = row.timeKey.currentState?.tryParseSeconds();
      if (swimTime == null) return;

      final event = _matchingSelection(eventOptions, row.event);
      if (event == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick an event for each time.')),
        );
        return;
      }

      parsedRows.add((event: event, timeSeconds: swimTime));
    }

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    var notes = _notesController.text.trim();
    if (_photoBytes != null) {
      try {
        final url =
            await ref.read(profilePhotoServiceProvider).uploadSchedulePhoto(
                  swimmer: swimmer,
                  fileName: _photoName ?? 'best-times.jpg',
                  bytes: _photoBytes!,
                );
        notes = notes.isEmpty
            ? 'Times photo: $url'
            : '$notes\nTimes photo: $url';
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not upload times photo.')),
          );
        }
      }
    }

    var savedCount = 0;
    String? lastError;

    for (final row in parsedRows) {
      final result = MeetResult(
        swimmerName: swimmer,
        meetName: _uploadSourceLabel,
        event: row.event.meetResultEvent,
        swimTime: row.timeSeconds,
        course: row.event.course,
        meetDate: _achievedDate,
        notes: notes.isEmpty ? null : notes,
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).addMeetResult(result);
      if (error != null) {
        lastError = error;
        break;
      }
      savedCount++;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedCount == 0
                ? 'Could not save best times: $lastError'
                : 'Saved $savedCount times, then hit an error: $lastError',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      if (savedCount > 0) Navigator.of(context).pop();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (mounted) Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          savedCount == 1
              ? 'Best time saved — your PBs are updated.'
              : '$savedCount best times saved — your PBs are updated.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final eventOptions = _eventOptions();

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
              'Upload your best times',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add one or more events. Saved times automatically sync to your '
              'PBs, dashboard cuts, and Athlete Passport.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('When you swam these times'),
              subtitle: Text(dateFormat.format(_achievedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _course,
              decoration: const InputDecoration(labelText: 'Course'),
              items: AppConstants.courses
                  .map(
                    (course) => DropdownMenuItem(
                      value: course,
                      child: Text(course),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _course = value;
                        for (final row in _rows) {
                          row.event = null;
                        }
                      });
                    },
            ),
            const SizedBox(height: 16),
            if (eventOptions.isEmpty)
              const Text(
                'Add birthday and gender in the Athlete Passport to load '
                'official USA Swimming events.',
              )
            else
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final currentSelection =
                    _matchingSelection(eventOptions, row.event);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Event ${index + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (_rows.length > 1)
                              IconButton(
                                onPressed:
                                    _isSaving ? null : () => _removeRow(index),
                                icon: const Icon(Icons.close),
                                tooltip: 'Remove event',
                              ),
                          ],
                        ),
                        DropdownButtonFormField<SwimEventOption>(
                          value: currentSelection,
                          decoration:
                              const InputDecoration(labelText: 'Event'),
                          isExpanded: true,
                          items: eventOptions
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(() => row.event = value),
                          validator: (value) =>
                              value == null ? 'Pick an event' : null,
                        ),
                        const SizedBox(height: 8),
                        SwimTimeEntryFields(key: row.timeKey),
                      ],
                    ),
                  ),
                );
              }),
            if (eventOptions.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isSaving ? null : _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add another event'),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Where these times came from',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _takePhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickPhotoFromFiles,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Upload photo'),
                  ),
                ),
              ],
            ),
            if (_photoName != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _photoName!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const SizedBox(height: 20),
            SwimIqSaveButton(
              label: 'Save best times',
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
}
