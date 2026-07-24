import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/passport_metrics.dart';
import '../core/utils/schedule_meet_resolver.dart';
import '../data/models/swim_schedule_entry.dart';

/// Sync status for the athlete's next meet from Log → Meets.
class UpcomingMeetSyncBanner extends StatelessWidget {
  const UpcomingMeetSyncBanner({
    super.key,
    required this.schedules,
    this.now,
  });

  final List<SwimScheduleEntry> schedules;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final entry = ScheduleMeetResolver.nextMeetOrRace(schedules, now: now);
    final synced = entry != null;
    final upcoming = synced && ScheduleMeetResolver.isUpcoming(entry, now: now);
    final line = synced
        ? ScheduleMeetResolver.formatSyncLine(entry)
        : ScheduleMeetResolver.formatSyncLine(null);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: synced
            ? AppColors.surfaceLight
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: synced
              ? AppColors.primary.withValues(alpha: 0.22)
              : const Color(0xFFFDBA74),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            synced ? Icons.event_available : Icons.event_busy,
            color: synced ? AppColors.primaryDeep : const Color(0xFFC2410C),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  synced
                      ? (upcoming
                          ? 'Upcoming meet synced'
                          : 'Next meet synced (Race Intelligence)')
                      : 'No upcoming meet synced',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  synced
                      ? line
                      : 'Add her meet on Log → Meets so Passport and Race '
                          'Intelligence stay in sync. '
                          '(${PassportMetrics.noUpcomingMeetLabel})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade800,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
