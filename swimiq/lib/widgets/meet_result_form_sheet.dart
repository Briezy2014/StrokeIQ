import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/swim_time.dart';
import '../data/models/meet_result.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
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
  final _meetNameController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  final _courseController =
      TextEditingController(text: AppConstants.courses.first);

  DateTime _meetDate = DateTime.now();
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
    _eventController.dispose();
    _timeController.dispose();
    _notesController.dispose();
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
      _photoBytes = bytes;
      _photoName = photo.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    try {
      final course = _courseController.text.trim().isEmpty
          ? AppConstants.courses.first
          : _courseController.text.trim();
      final swimTime = SwimTime.toSeconds(_timeController.text);

      var notes = _notesController.text.trim();
      if (_photoBytes != null) {
        try {
          final url =
              await ref.read(profilePhotoServiceProvider).uploadSchedulePhoto(
                    swimmer: swimmer,
                    fileName: _photoName ?? 'meet-result.jpg',
                    bytes: _photoBytes!,
                  );
          notes = notes.isEmpty ? 'Results photo: $url' : '$notes\nResults photo: $url';
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
        event: _eventController.text.trim(),
        swimTime: swimTime,
        course: course,
        meetDate: _meetDate,
        notes: notes.isEmpty ? null : notes,
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).addMeetResult(result);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save meet result: $error')),
        );
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Official meet result saved.')),
      );
    } on FormatException {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter result time like 35.43, 1:24.32, or 5:31.43.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

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
              'Log official meet result',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter times manually or attach a results / heat sheet photo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _meetNameController,
              decoration: const InputDecoration(labelText: 'Meet name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Meet date'),
              subtitle: Text(dateFormat.format(_meetDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
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
                labelText: 'Result time',
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
                labelText: 'Course',
                hintText: 'SCY, SCM, or LCM',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
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
              label: 'Save official result',
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
