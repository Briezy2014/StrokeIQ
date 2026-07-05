import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../core/utils/swimiq_gender.dart';
import '../../core/utils/swim_time.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class UsaStandardsScreen extends ConsumerStatefulWidget {
  const UsaStandardsScreen({super.key});

  @override
  ConsumerState<UsaStandardsScreen> createState() => _UsaStandardsScreenState();
}

class _UsaStandardsScreenState extends ConsumerState<UsaStandardsScreen> {
  bool _importing = false;
  final _searchController = TextEditingController();
  final _ageGroupController = TextEditingController();
  final _genderController = TextEditingController();
  final _courseController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _ageGroupController.dispose();
    _genderController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _importStandards() async {
    setState(() => _importing = true);
    final error =
        await ref.read(swimmerDataProvider.notifier).importUsaStandards();
    if (!mounted) return;
    setState(() => _importing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? '2024-2028 motivational standards synced to Supabase.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final catalog = data.motivationalStandards;
        final pbs = data.personalBests;
        final ageGroup = SwimIqAgeGroup.fromProfile(data.profile);
        final gender = SwimIqGender.standardsGender(data.profile);

        if (_ageGroupController.text.isEmpty) {
          _ageGroupController.text = ageGroup;
        }
        if (_genderController.text.isEmpty) {
          _genderController.text = gender;
        }

        final results = catalog.search(
          ageGroup: _optional(_ageGroupController.text),
          gender: _optional(_genderController.text),
          course: _optional(_courseController.text),
          query: _optional(_searchController.text),
        );

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqScreenHeader(
              title: 'USA Swimming Standards',
              subtitle: catalog.versionLabel,
            ),
            const SizedBox(height: 8),
            Text(
              'Valid through ${catalog.bundle.effectiveThrough}. '
              '${catalog.events.length} official age-group events loaded from the 2024-2028 motivational standards.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SwimIqSaveButton(
              label: 'Sync Standards to Supabase',
              isSaving: _importing,
              onPressed: _importStandards,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search events',
                hintText: '50 Butterfly SCY, 100 IM, Freestyle',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ageGroupController,
              decoration: const InputDecoration(
                labelText: 'Age group',
                hintText: '10 & under, 11-12, 13-14, 15-16, 17-18',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _genderController,
              decoration: const InputDecoration(
                labelText: 'Gender',
                hintText: 'Girls or Boys',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _courseController,
              decoration: const InputDecoration(
                labelText: 'Course',
                hintText: 'SCY, SCM, or LCM',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text('Your PB Cuts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (pbs.isEmpty)
              const EmptyStateMessage(
                message: 'Add training sessions to compare against standards.',
              )
            else
              ...pbs.map((pb) {
                final cut = MotivationalCut.forRaceLog(
                  catalog: catalog,
                  profile: data.profile,
                  log: pb,
                );
                return SwimIqEventListTile(
                  title: '${pb.distance} ${pb.stroke} · ${pb.course}',
                  subtitle:
                      '$ageGroup · $gender · ${cut ?? 'Below B'} motivational cut',
                  trailing: SwimTime.fromSeconds(pb.timeSeconds),
                );
              }),
            const SizedBox(height: 24),
            Text(
              'Standards Table (${results.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (results.isEmpty)
              const EmptyStateMessage(
                message: 'No standards match this search.',
              )
            else
              ...results.take(60).map((event) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.event,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.ageGroup} · ${event.gender} · ${event.course}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: UsaMotivationalStandardsCatalog
                              .standardLevels
                              .map(
                            (level) => Chip(
                              label: Text(
                                '$level ${SwimTime.fromSeconds(event.cuts[level] ?? 0)}',
                              ),
                            ),
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  String? _optional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
