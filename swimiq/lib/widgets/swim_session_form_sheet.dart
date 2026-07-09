import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/swimiq_camera_capture.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/swim_analytics.dart';
import '../core/utils/swim_time.dart';
import '../data/models/race_log.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import 'swimiq_ui.dart';

Future<void> showSwimSessionFormSheet(
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
      child: SwimSessionFormSheet(startWithPhotoPicker: startWithPhotoPicker),
    ),
  );
}

class SwimSessionFormSheet extends ConsumerStatefulWidget {
  const SwimSessionFormSheet({super.key, this.startWithPhotoPicker = false});

  final bool startWithPhotoPicker;

  @override
  ConsumerState<SwimSessionFormSheet> createState() => _SwimSessionFormSheetState();
}

class _SwimSessionFormSheetState extends ConsumerState<SwimSessionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  final _strokeController =
      TextEditingController(text: AppConstants.strokes.first);
  final _courseController =
      TextEditingController(text: AppConstants.courses.first);

  int _distance = 100;
  DateTime _sessionDate = DateTime.now();
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
    _timeController.dispose();
    _notesController.dispose();
    _strokeController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _sessionDate = picked);
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

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    try {
      final timeSeconds = SwimTime.toSeconds(_timeController.text);
      final currentData = ref.read(swimmerDataProvider).value;
      final previousLogs = currentData?.raceLogs ?? [];

      final stroke = _strokeController.text.trim().isEmpty
          ? AppConstants.strokes.first
          : _strokeController.text.trim();
      final course = _courseController.text.trim().isEmpty
          ? AppConstants.courses.first
          : _courseController.text.trim();

      var notes = _notesController.text.trim();
      if (_photoBytes != null) {
        try {
          final url =
              await ref.read(profilePhotoServiceProvider).uploadSchedulePhoto(
                    swimmer: swimmer,
                    fileName: _photoName ?? 'training.jpg',
                    bytes: _photoBytes!,
                  );
          notes = notes.isEmpty ? 'Training photo: $url' : '$notes\nTraining photo: $url';
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not upload training photo.')),
            );
          }
        }
      }

      final isPb = SwimAnalytics.isNewPersonalBest(
        previousLogs: previousLogs,
        stroke: stroke,
        distance: _distance,
        course: course,
        timeSeconds: timeSeconds,
      );

      final log = RaceLog(
        swimmer: swimmer,
        event: '$_distance $stroke',
        distance: _distance,
        stroke: stroke,
        course: course,
        timeSeconds: timeSeconds,
        date: _sessionDate,
        notes: notes.isEmpty ? null : notes,
      );

      final error =
          await ref.read(swimmerDataProvider.notifier).addRaceLog(log);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save session: $error')),
        );
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isPb ? 'New personal best saved.' : 'Swim session saved.',
          ),
        ),
      );
    } on FormatException {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter time like 35.43, 1:24.32, or 5:31.43.',
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
              'Log swim session',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter times manually or attach a workout photo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _strokeController,
              decoration: const InputDecoration(
                labelText: 'Stroke',
                hintText:
                    'Freestyle, Backstroke, Breaststroke, Butterfly, or IM',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '$_distance',
              decoration: const InputDecoration(labelText: 'Distance'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed >= 25) {
                  setState(() => _distance = parsed);
                }
              },
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed < 25) {
                  return 'Distance must be at least 25';
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
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'Example: 35.43 or 1:24.32',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Time is required';
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
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Splits, stroke count, how the swim felt, etc.',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(dateFormat.format(_sessionDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                            _photoBytes = null;
                            _photoName = null;
                          }),
                  child: const Text('Remove photo'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SwimIqSaveButton(
              label: 'Save swim session',
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
