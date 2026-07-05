import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

class PersonalBestsScreen extends StatelessWidget {
  const PersonalBestsScreen({super.key, required this.data});

  final SwimmerData data;

  @override
  Widget build(BuildContext context) {
    final personalBests = SwimAnalytics.personalBests(data.raceLogs);
    final dateFormat = DateFormat.yMMMd();

    if (personalBests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EmptyStateMessage(
            message:
                'No personal bests yet. Add swim sessions to unlock this page.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Personal Bests',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        ...personalBests.map(
          (log) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${log.distance} ${log.stroke}'),
              subtitle: Text('${log.course} · ${dateFormat.format(log.date)}'),
              trailing: Text(
                SwimTime.fromSeconds(log.timeSeconds),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
