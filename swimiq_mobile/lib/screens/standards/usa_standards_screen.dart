import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/swim_time_utils.dart';
import '../../providers/standards_providers.dart';
import '../../widgets/standards/standards_empty_state.dart';
import '../../widgets/standards/standards_filter_bar.dart';
import '../../widgets/swimiq_app_bar.dart';

/// Searchable USA Swimming motivational standards reference screen.
class UsaStandardsScreen extends ConsumerStatefulWidget {
  const UsaStandardsScreen({super.key});

  @override
  ConsumerState<UsaStandardsScreen> createState() => _UsaStandardsScreenState();
}

class _UsaStandardsScreenState extends ConsumerState<UsaStandardsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final standardsLoaded = ref.watch(standardsLoadedProvider);
    final search = _searchController.text;
    final standardsAsync = ref.watch(filteredStandardsProvider(search));
    final selectedAgeGroup = ref.watch(resolvedAgeGroupProvider);

    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'USA Standards'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StandardsFilterBar(),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search events',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (!standardsLoaded)
            const StandardsEmptyState()
          else if (selectedAgeGroup == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select an age group above or add a birthday to your '
                  'Athlete Passport to load standards for your swimmer.',
                ),
              ),
            )
          else
            standardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Could not load standards: $error'),
              data: (standards) {
                if (standards.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No standards match your filters.'),
                    ),
                  );
                }

                return Column(
                  children: standards.map((standard) {
                    return Card(
                      child: ListTile(
                        title: Text(standard.event),
                        subtitle: Text(
                          '${standard.ageGroup} · ${standard.gender} · ${standard.course}',
                        ),
                        trailing: Text(
                          'AAAA ${SwimTimeUtils.secondsToSwimTime(standard.aaaaTime)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      standard.event,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 12),
                                    _LevelRow(label: 'B', value: standard.bTime),
                                    _LevelRow(label: 'BB', value: standard.bbTime),
                                    _LevelRow(label: 'A', value: standard.aTime),
                                    _LevelRow(label: 'AA', value: standard.aaTime),
                                    _LevelRow(label: 'AAA', value: standard.aaaTime),
                                    _LevelRow(label: 'AAAA', value: standard.aaaaTime),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(label)),
          Text(
            SwimTimeUtils.secondsToSwimTime(value),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
