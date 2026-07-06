import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/meet_schedule_queue_item.dart';
import '../data/models/scheduled_meet.dart';
import '../providers/meet_schedule_provider.dart';
import '../providers/swimmer_data_provider.dart';

/// Photo-based meet schedule — works for any team (no website scraping).
class MeetScheduleSection extends ConsumerWidget {
  const MeetScheduleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meets = ref.watch(scheduledMeetsProvider);
    final queue = ref.watch(meetQueueProvider);
    final upload = ref.watch(meetScheduleUploadProvider);
    final notifier = ref.read(meetScheduleUploadProvider.notifier);
    final profile = ref.watch(swimmerDataProvider).value?.profile;
    final attendingIds = profile?.attendingMeetIds.toSet() ?? {};
    final dateFormat = DateFormat.yMMMd();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming meets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Snap or upload a photo of your team meet schedule — any club, '
              'any season. SwimIQ reads the dates with AI and adds them to your '
              'queue. Mark which meets you are attending for Passport and Meet Day.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: upload.isProcessing
                  ? null
                  : () => _pickSchedulePhoto(context, ref),
              icon: upload.isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined),
              label: Text(
                upload.isProcessing
                    ? 'Reading schedule…'
                    : 'Photo of meet schedule',
              ),
            ),
            if (queue.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'My queue',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => notifier.clearQueue(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...queue.take(5).map(
                    (item) => _QueueTile(item: item, dateFormat: dateFormat),
                  ),
            ],
            if (meets.isEmpty && !upload.isProcessing) ...[
              const SizedBox(height: 12),
              const Text('No upcoming meets yet — upload a schedule photo.'),
            ] else if (meets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mark meets you are attending',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ...meets.map(
                (meet) => _MeetAttendanceTile(
                  meet: meet,
                  dateFormat: dateFormat,
                  isAttending: attendingIds.contains(meet.externalId),
                  onChanged: (value) async {
                    final error = await notifier.setAttending(
                      meetExternalId: meet.externalId,
                      attending: value,
                    );
                    if (!context.mounted) return;
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickSchedulePhoto(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read that image. Try another file.'),
        ),
      );
      return;
    }

    final error = await ref.read(meetScheduleUploadProvider.notifier).uploadSchedulePhoto(
          bytes: bytes,
          fileName: file.name,
        );

    if (!context.mounted) return;
    final count = ref.read(scheduledMeetsProvider).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Schedule read — $count upcoming meet(s) on your calendar.',
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.item,
    required this.dateFormat,
  });

  final MeetScheduleQueueItem item;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.status) {
      MeetQueueStatus.processing => Icons.hourglass_top,
      MeetQueueStatus.done => Icons.check_circle_outline,
      MeetQueueStatus.error => Icons.error_outline,
      MeetQueueStatus.queued => Icons.schedule,
    };
    final color = switch (item.status) {
      MeetQueueStatus.done => Colors.green.shade700,
      MeetQueueStatus.error => Colors.red.shade700,
      _ => Theme.of(context).colorScheme.primary,
    };

    final subtitle = switch (item.status) {
      MeetQueueStatus.done =>
        '${item.meetCount} meet(s) added · ${dateFormat.format(item.uploadedAt)}',
      MeetQueueStatus.error => item.error ?? 'Could not read schedule',
      MeetQueueStatus.processing => 'Gemini is reading your schedule…',
      MeetQueueStatus.queued => 'Waiting…',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(item.fileName),
      subtitle: Text(subtitle),
    );
  }
}

class _MeetAttendanceTile extends StatelessWidget {
  const _MeetAttendanceTile({
    required this.meet,
    required this.dateFormat,
    required this.isAttending,
    required this.onChanged,
  });

  final ScheduledMeet meet;
  final DateFormat dateFormat;
  final bool isAttending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      dateFormat.format(meet.startDate),
      if (meet.location != null && meet.location!.isNotEmpty) meet.location!,
      if (meet.course != null && meet.course!.isNotEmpty) meet.course!,
    ];

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: isAttending,
      onChanged: (value) => onChanged(value ?? false),
      title: Text(meet.name),
      subtitle: Text(subtitleParts.join(' · ')),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
