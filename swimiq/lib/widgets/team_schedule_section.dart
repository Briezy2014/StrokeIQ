import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/scheduled_meet.dart';
import '../providers/swimmer_data_provider.dart';
import '../providers/team_schedule_provider.dart';

class TeamScheduleSection extends ConsumerWidget {
  const TeamScheduleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(teamScheduleProvider);
    final notifier = ref.read(teamScheduleProvider.notifier);
    final data = ref.watch(swimmerDataProvider).value;
    final profile = data?.profile;
    final attendingIds = profile?.attendingMeetIds.toSet() ?? {};
    final dateFormat = DateFormat.yMMMd();
    final isCoa = notifier.isCoaTeam;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCoa ? 'Central Ohio Aquatics schedule' : 'Team meet schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isCoa
                  ? 'Pull upcoming meets from the COA SportsEngine calendar. '
                      'Mark the ones you are attending — they feed Meet Day, '
                      'Race Intelligence, and your Passport upcoming meet.'
                  : 'Set your team to COA in Passport to auto-match Central '
                      'Ohio Aquatics, or sync any time to load the club calendar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: schedule.isSyncing
                  ? null
                  : () async {
                      final error = await notifier.syncCoaSchedule();
                      if (!context.mounted) return;
                      final count = ref.read(teamScheduleProvider).meets.length;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error ?? 'Loaded $count upcoming team events from COA.',
                          ),
                        ),
                      );
                    },
              icon: schedule.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(
                schedule.isSyncing
                    ? 'Pulling COA schedule…'
                    : 'Pull from COA website',
              ),
            ),
            if (schedule.lastSyncedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last synced ${dateFormat.format(schedule.lastSyncedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (schedule.error != null) ...[
              const SizedBox(height: 8),
              Text(
                schedule.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (schedule.pdfLinks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Full-season PDF schedules',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ...schedule.pdfLinks.map(
                (link) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(link.label),
                  subtitle: link.updated == null ? null : Text('Updated ${link.updated}'),
                  onTap: link.url.isEmpty
                      ? null
                      : () => launchUrl(
                            Uri.parse(link.url),
                            mode: LaunchMode.externalApplication,
                          ),
                ),
              ),
            ],
            if (schedule.meets.isEmpty && !schedule.isSyncing) ...[
              const SizedBox(height: 12),
              const Text('No upcoming team events loaded yet.'),
            ] else if (schedule.meets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mark meets you are attending',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ...schedule.meets.map(
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
      if (meet.categories.isNotEmpty) meet.categories.join(', '),
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
