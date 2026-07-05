import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/standard_level.dart';
import '../../providers/standards_providers.dart';
import '../../services/standards_analytics.dart';
import '../../widgets/standards/standard_progress_card.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/swimiq_app_bar.dart';

/// Goals placeholder wired to motivational standard target levels.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardsLoaded = ref.watch(standardsLoadedProvider);
    final selectedLevel = ref.watch(selectedGoalLevelProvider);

    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Goals'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!standardsLoaded)
            const StandardsEmptyState()
          else ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose a motivational level target. Required goal times will '
                  'be calculated automatically from the shared standards repository.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target motivational level',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    StandardLevelPicker(
                      selected: selectedLevel,
                      onChanged: (level) {
                        ref.read(selectedGoalLevelProvider.notifier).state = level;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Goal creation and event selection will be added in the next '
                  'milestone. All goal times will come from motivational_standards.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

double? goalTimeFromStandard({
  required StandardLevel level,
  required dynamic standard,
}) {
  return StandardsAnalytics.goalTimeForLevel(
    standard: standard,
    level: level,
  );
}
