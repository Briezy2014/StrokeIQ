import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/usa_standards_service.dart';
import '../../core/utils/swimiq_age_group.dart';
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
  String _filterStroke = 'All';

  Future<void> _importStandards() async {
    setState(() => _importing = true);
    final error =
        await ref.read(swimmerDataProvider.notifier).importUsaStandards();
    if (!mounted) return;
    setState(() => _importing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'USA Swimming standards imported to Supabase.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final standards = data.usaStandards;
        final pbs = data.personalBests;
        final ageGroup = SwimIqAgeGroup.fromProfile(data.profile);
        final summary = data.passportSnapshot(swimmer).usaStandardsSummary;
        final strokes = {
          'All',
          ...standards.map((s) => s.stroke),
        }.toList();

        final filtered = _filterStroke == 'All'
            ? standards
            : standards.where((s) => s.stroke == _filterStroke).toList();

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqScreenHeader(
              title: 'USA Swimming Standards',
              subtitle: summary,
            ),
            const SizedBox(height: 16),
            SwimIqSaveButton(
              label: 'Import Seed Standards to Supabase',
              isSaving: _importing,
              onPressed: _importStandards,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _filterStroke,
              decoration: const InputDecoration(labelText: 'Filter by stroke'),
              items: strokes
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _filterStroke = v!),
            ),
            const SizedBox(height: 16),
            Text('Your PB Cuts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (pbs.isEmpty)
              const EmptyStateMessage(
                message: 'Add training sessions to compare against standards.',
              )
            else
              ...pbs.map((pb) {
                final cut = UsaStandardsService.highestCutForTime(
                  standards: standards,
                  stroke: pb.stroke,
                  distance: pb.distance,
                  course: pb.course,
                  swimmerTime: pb.timeSeconds,
                  ageGroup: ageGroup,
                );
                return SwimIqEventListTile(
                  title: '${pb.distance} ${pb.stroke} · ${pb.course}',
                  subtitle: 'Age group: $ageGroup',
                  trailing: cut ?? 'Below B',
                );
              }),
            const SizedBox(height: 24),
            Text('Standards Table', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const EmptyStateMessage(
                message: 'No standards loaded for this filter.',
              )
            else
              ...filtered.take(40).map(
                    (standard) => SwimIqEventListTile(
                      title:
                          '${standard.ageGroup} ${standard.gender} · ${standard.distance} ${standard.stroke} · ${standard.course}',
                      subtitle: standard.standardLevel,
                      trailing: SwimTime.fromSeconds(standard.timeSeconds),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
