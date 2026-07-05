import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/standards_providers.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/swimiq_app_bar.dart';

/// Meet results placeholder wired to motivational standards evaluation.
class MeetResultsScreen extends ConsumerWidget {
  const MeetResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardsLoaded = ref.watch(standardsLoadedProvider);

    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Meet Results'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!standardsLoaded)
            const StandardsEmptyState()
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Meet results will automatically determine the standard achieved, '
                  'previous standard, new standard, and time improvements using the '
                  'shared motivational standards repository.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
