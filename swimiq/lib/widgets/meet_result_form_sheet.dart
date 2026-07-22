import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/swim_event_options.dart';
import '../core/utils/swimiq_camera_capture.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/swim_time.dart';
import '../data/models/meet_result.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import 'swim_time_entry_fields.dart';
import 'swimiq_ui.dart';

Future<void> showMeetResultFormSheet(
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
      child: MeetResultFormSheet(startWithPhotoPicker: startWithPhotoPicker),
    ),
  );
}

class MeetResultFormSheet extends ConsumerStatefulWidget {
  const MeetResultFormSheet({super.key, this.startWithPhotoPicker = false});

  final bool startWithPhotoPicker;

  @override
  ConsumerState<MeetResultFormSheet> createState() =>
      _MeetResultFormSheetState();
}

class _MeetResultFormSheetState extends ConsumerState<MeetResultFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _timeFieldsKey = GlobalKey<SwimTimeEntryFieldsState>();
  final _meetNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _meetDate = DateTime.now();
  String _course = AppConstants.courses.first;
  SwimEventOption? _selectedEvent;
  bool _isSaving = false;
  Uint8List? _photoBytes;
  String? _photoName;

  @override
  void initState() {
    super.initState();
    if (widget.startWithPhotoPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhotoFromFiles());
    }
  }

  @override
  void dispose() {
    _meetNameController.dispose();
    _locationController.dispose();
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

  SwimEventOption? _matchingSelection(List<SwimEventOption> options) {
    if (options.isEmpty) return null;
    final selected = _selectedEvent;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _meetDate = picked);
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

    final timeError = _timeFieldsKey.currentState?.validate();
    if (timeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timeError)),
      );
      return;
    }

    final swimTime = _timeFieldsKey.currentState!.tryParseSeconds();
    if (swimTime == null) return;

    final swimmer = ref.read(activeSwimmerProvider);
    final selectedEvent = _matchingSelection(_eventOptions());
    if (swimmer == null || selectedEvent == null) return;

    setState(() => _isSaving = true);

    try {
      var notes = _notesController.text.trim();
      final location = _locationController.text.trim();
      if (location.isNotEmpty) {
        notes = notes.isEmpty ? 'Pool: $location' : 'Pool: $location\n$notes';
      }

      if (_photoBytes != null) {
        try {
          final url =
              await ref.read(profilePhotoServiceProvider).uploadSchedulePhoto(
                    swimmer: swimmer,
                    fileName: _photoName ?? 'meet-result.jpg',
                    bytes: _photoBytes!,
                  );
          notes = notes.isEmpty
              ? 'Results photo: $url'
              : '$notes\nResults photo: $url';
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not upload results photo.')),
            );
          }
        }
      }

      final result = MeetResult(
        swimmerName: swimmer,
        meetName: _meetNameController.text.trim(),
        event: selectedEvent.meetResultEvent,
        swimTime: swimTime,
        course: selectedEvent.course,
        meetDate: _meetDate,
        notes: notes.isEmpty ? null : notes,
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).addMeetResult(result);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save meet result: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Meet result saved.')),
      );
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final eventOptions = _eventOptions();
    final currentSelection = _matchingSelection(eventOptions);

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
              'New meet result',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Log the meet, pick your event, and enter your official time.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _meetNameController,
              decoration: const InputDecoration(
                labelText: 'Meet or session name',
                hintText: '2026 OH LC Central Regional Championships',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(dateFormat.format(_meetDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Pool / location (optional)',
              ),
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
                        _selectedEvent = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            if (eventOptions.isEmpty)
              const Text(
                'Add birthday and gender in the Athlete Passport to load '
                'official USA Swimming events.',
              )
            else
              DropdownButtonFormField<SwimEventOption>(
                value: currentSelection,
                decoration: const InputDecoration(labelText: 'Event'),
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
                    : (value) => setState(() => _selectedEvent = value),
                validator: (value) => value == null ? 'Pick an event' : null,
              ),
            const SizedBox(height: 12),
            SwimTimeEntryFields(key: _timeFieldsKey),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Finals notes, splits, or coach feedback',
              ),
              maxLines: 3,
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
                    label: const Text('Upload'),
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
            if (_photoBytes != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _photoBytes!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
}
