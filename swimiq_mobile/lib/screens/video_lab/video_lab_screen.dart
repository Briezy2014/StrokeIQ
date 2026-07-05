import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_providers.dart';
import '../../providers/standards_providers.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/swimiq_app_bar.dart';

/// Video Lab placeholder with standards-aware AI coach messaging.
class VideoLabScreen extends ConsumerWidget {
  const VideoLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardsLoaded = ref.watch(standardsLoadedProvider);
    final favoriteEvent = ref.watch(swimmerProfileProvider).maybeWhen(
          data: (profile) => profile?.favoriteEvent,
          orElse: () => null,
        );

    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Video Lab'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!standardsLoaded)
            const StandardsEmptyState()
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach (standards-aware)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Instead of generic comments like "Nice swim," the AI Coach '
                      'will reference your current motivational level, the next '
                      'level, and the exact time gap — for example:\n\n'
                      '"You are currently AA in the 100 Butterfly. You are 0.72 '
                      'seconds from AAA. Based on today\'s race, improving your '
                      'breakout and maintaining stroke tempo over the final 25 '
                      'meters is likely to provide the largest improvement toward AAA."',
                    ),
                    if (favoriteEvent != null) ...[
                      const SizedBox(height: 12),
                      Text('Focus event: $favoriteEvent'),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
