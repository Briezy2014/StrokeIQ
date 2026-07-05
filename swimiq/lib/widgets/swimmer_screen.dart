import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';

typedef SwimmerScreenBuilder = Widget Function(
  BuildContext context,
  WidgetRef ref,
  SwimmerData data,
  String swimmerName,
);

/// Single source of truth wrapper for every SwimIQ feature screen.
class SwimmerScreen extends ConsumerWidget {
  const SwimmerScreen({
    super.key,
    required this.builder,
  });

  final SwimmerScreenBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swimmer = ref.watch(activeSwimmerProvider);
    final dataAsync = ref.watch(swimmerDataProvider);

    if (swimmer == null || swimmer.isEmpty) {
      return const Center(child: Text('No swimmer selected.'));
    }

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text('Could not load swimmer data: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(swimmerDataProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (data) {
        if (data == null) {
          return const Center(child: Text('No swimmer data loaded.'));
        }
        return builder(context, ref, data, swimmer);
      },
    );
  }
}
