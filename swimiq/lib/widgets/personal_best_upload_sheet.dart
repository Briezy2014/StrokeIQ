import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/services/best_times_extract_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/best_times_event_parser.dart';
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

enum _EntryMode { manual, multipleFromPhoto }

class _BestTimeRow {
  _BestTimeRow({
    this.event,
    this.meetName,
    this.achievedDate,
  }) : timeKey = GlobalKey<SwimTimeEntryFieldsState>();

  SwimEventOption? event;
  String? meetName;
  DateTime? achievedDate;
  final GlobalKey<SwimTimeEntryFieldsState> timeKey;
  double? pendingTimeSeconds;
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
  _EntryMode _mode = _EntryMode.manual;
  bool _isSaving = false;
  bool _isExtracting = false;
  Uint8List? _photoBytes;
  String? _photoName;
  String? _extractStatus;

  static const _uploadSourceLabel = 'Uploaded best times';
  static const _multipleEventLabel = 'Multiple (from photo)';

  @override
  void initState() {
    super.initState();
    if (widget.startWithPhotoPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _mode = _EntryMode.multipleFromPhoto);
        _pickPhotoFromFiles();
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<SwimEventOption> _eventOptions({String? course}) {
    final data = ref.read(swimmerDataProvider).value;
    if (data == null) return const [];
    return SwimEventOptions.forProfile(
      catalog: data.motivationalStandards,
      profile: data.profile,
      course: course ?? _course,
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
    await _onPhotoSelected(file.bytes!, file.name);
  }

  Future<void> _takePhoto() async {
    final photo = await captureSwimIqPhoto(context);
    if (photo == null || !mounted) return;
    await _onPhotoSelected(photo.bytes, photo.fileName);
  }

  Future<void> _onPhotoSelected(Uint8List bytes, String name) async {
    setState(() {
      _photoBytes = bytes;
      _photoName = name;
      _extractStatus = null;
    });
    if (_mode == _EntryMode.multipleFromPhoto) {
      await _extractTimesFromPhoto();
    }
  }

  Future<void> _extractTimesFromPhoto() async {
    final bytes = _photoBytes;
    final name = _photoName;
    if (bytes == null || name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload a Best Times History photo first.'),
        ),
      );
      return;
    }

    setState(() {
      _isExtracting = true;
      _extractStatus = 'Reading times from your photo…';
    });

    try {
      final extracted =
          await ref.read(bestTimesExtractServiceProvider).extractFromPhoto(
                bytes: bytes,
                fileName: name,
                courseHint: _course,
              );

      final detectedCourse =
          BestTimesEventParser.normalizeCourse(extracted.detectedCourse) ??
              _course;
      final options = _eventOptions(course: detectedCourse);
      final nextRows = <_BestTimeRow>[];

      for (final item in extracted.times) {
        final course = BestTimesEventParser.normalizeCourse(item.course) ??
            detectedCourse;
        final event = BestTimesEventParser.matchOption(
          eventRaw: item.eventRaw,
          course: course,
          options: _eventOptions(course: course).isNotEmpty
              ? _eventOptions(course: course)
              : options,
        );
        final seconds = BestTimesEventParser.parseTimeSeconds(item.timeRaw);
        if (event == null || seconds == null) continue;
        nextRows.add(
          _BestTimeRow(
            event: event,
            meetName: item.meetName?.trim().isNotEmpty == true
                ? item.meetName!.trim()
                : null,
            achievedDate: BestTimesEventParser.parseDate(item.date),
          )..pendingTimeSeconds = seconds,
        );
      }

      if (!mounted) return;
      if (nextRows.isEmpty) {
        setState(() {
          _isExtracting = false;
          _extractStatus =
              'No readable swim times found. Try a clearer screenshot.';
        });
        return;
      }

      setState(() {
        _course = detectedCourse;
        _rows
          ..clear()
          ..addAll(nextRows);
        _isExtracting = false;
        _extractStatus =
            'Loaded ${nextRows.length} times from photo. Review, then save.';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final row in _rows) {
          final seconds = row.pendingTimeSeconds;
          if (seconds != null) {
            row.timeKey.currentState?.setFromSeconds(seconds);
          }
        }
      });
    } on BestTimesExtractException catch (error) {
      if (!mounted) return;
      setState(() {
        _isExtracting = false;
        _extractStatus = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isExtracting = false;
        _extractStatus = 'Could not read that photo. Try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read that photo: $error')),
      );
    }
  }

  Future<void> _save() async {
    if (_mode == _EntryMode.multipleFromPhoto &&
        (_photoBytes == null || _rows.every((r) => r.event == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload a Best Times History photo so SwimIQ can fill multiple events.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final eventOptions = _eventOptions();
    if (eventOptions.isEmpty && _mode == _EntryMode.manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add birthday and gender in the Athlete Passport to load events.',
          ),
        ),
      );
      return;
    }

    final parsedRows = <({
      SwimEventOption event,
      double timeSeconds,
      DateTime meetDate,
      String meetName,
    })>[];

    for (final row in _rows) {
      final timeError = row.timeKey.currentState?.validate();
      if (timeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(timeError)),
        );
        return;
      }

      final swimTime = row.timeKey.currentState?.tryParseSeconds() ??
          row.pendingTimeSeconds;
      if (swimTime == null) return;

      final event = row.event ?? _matchingSelection(eventOptions, row.event);
      if (event == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick an event for each time.')),
        );
        return;
      }

      parsedRows.add((
        event: event,
        timeSeconds: swimTime,
        meetDate: row.achievedDate ?? _achievedDate,
        meetName: row.meetName?.trim().isNotEmpty == true
            ? row.meetName!.trim()
            : _uploadSourceLabel,
      ));
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
        meetName: row.meetName,
        event: row.event.meetResultEvent,
        swimTime: row.timeSeconds,
        course: row.event.course,
        meetDate: row.meetDate,
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
    final busy = _isSaving || _isExtracting;

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
              _mode == _EntryMode.multipleFromPhoto
                  ? 'Choose Multiple (from photo), upload a Best Times History '
                      'screenshot, and SwimIQ fills every event it can read.'
                  : 'Add one or more events manually, or switch Event to '
                      'Multiple (from photo) to load a whole list from a screenshot.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_EntryMode>(
              value: _mode,
              decoration: const InputDecoration(labelText: 'Event'),
              items: const [
                DropdownMenuItem(
                  value: _EntryMode.manual,
                  child: Text('Single / manual events'),
                ),
                DropdownMenuItem(
                  value: _EntryMode.multipleFromPhoto,
                  child: Text(_multipleEventLabel),
                ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _mode = value;
                        _extractStatus = null;
                        if (value == _EntryMode.manual && _rows.isEmpty) {
                          _rows.add(_BestTimeRow());
                        }
                      });
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _course,
              decoration: InputDecoration(
                labelText: _mode == _EntryMode.multipleFromPhoto
                    ? 'Course (hint if photo is unclear)'
                    : 'Course',
              ),
              items: AppConstants.courses
                  .map(
                    (course) => DropdownMenuItem(
                      value: course,
                      child: Text(course),
                    ),
                  )
                  .toList(),
              onChanged: busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _course = value;
                        if (_mode == _EntryMode.manual) {
                          for (final row in _rows) {
                            row.event = null;
                          }
                        }
                      });
                    },
            ),
            if (_mode == _EntryMode.manual) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('When you swam these times'),
                subtitle: Text(dateFormat.format(_achievedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: busy ? null : _pickDate,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _takePhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : _pickPhotoFromFiles,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(
                      _mode == _EntryMode.multipleFromPhoto
                          ? 'Upload times photo'
                          : 'Upload photo',
                    ),
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
            if (_mode == _EntryMode.multipleFromPhoto) ...[
              const SizedBox(height: 8),
              if (_isExtracting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              if (_extractStatus != null)
                Text(
                  _extractStatus!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                ),
              if (_photoBytes != null && !_isExtracting)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: busy ? null : _extractTimesFromPhoto,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Re-read times from photo'),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            if (_mode == _EntryMode.manual && eventOptions.isEmpty)
              const Text(
                'Add birthday and gender in the Athlete Passport to load '
                'official USA Swimming events.',
              )
            else if (_mode == _EntryMode.multipleFromPhoto &&
                _rows.every((r) => r.event == null))
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'Upload a Best Times History screenshot (like TeamUnify). '
                  'SwimIQ will add every event/time it can read — you do not '
                  'pick each event one by one.',
                ),
              )
            else
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final rowCourse = row.event?.course ?? _course;
                final rowOptions = _eventOptions(course: rowCourse);
                final currentSelection = row.event == null
                    ? null
                    : _matchingSelection(
                        rowOptions.isNotEmpty ? rowOptions : eventOptions,
                        row.event,
                      );

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
                                _mode == _EntryMode.multipleFromPhoto
                                    ? (row.event?.label ?? 'Event ${index + 1}')
                                    : 'Event ${index + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (_rows.length > 1)
                              IconButton(
                                onPressed: busy ? null : () => _removeRow(index),
                                icon: const Icon(Icons.close),
                                tooltip: 'Remove event',
                              ),
                          ],
                        ),
                        if (_mode == _EntryMode.manual)
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
                            onChanged: busy
                                ? null
                                : (value) => setState(() => row.event = value),
                            validator: (value) =>
                                value == null ? 'Pick an event' : null,
                          )
                        else ...[
                          Text(
                            '${row.event?.label ?? 'Unknown event'} · ${row.event?.course ?? _course}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (row.meetName != null || row.achievedDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [
                                  if (row.achievedDate != null)
                                    dateFormat.format(row.achievedDate!),
                                  if (row.meetName != null) row.meetName!,
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                        const SizedBox(height: 8),
                        SwimTimeEntryFields(key: row.timeKey),
                      ],
                    ),
                  ),
                );
              }),
            if (_mode == _EntryMode.manual && eventOptions.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: busy ? null : _addRow,
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
            const SizedBox(height: 20),
            SwimIqSaveButton(
              label: _mode == _EntryMode.multipleFromPhoto
                  ? 'Save all best times'
                  : 'Save best times',
              isSaving: _isSaving,
              onPressed: _isExtracting ? null : _save,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
