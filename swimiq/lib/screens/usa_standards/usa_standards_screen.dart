import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/usa_standards_service.dart';
import '../../core/utils/swim_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

class UsaStandardsScreen extends ConsumerStatefulWidget {
  const UsaStandardsScreen({super.key, required this.data});

  final SwimmerData data;

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
          error ??
              'USA Swimming standards imported to Supabase. '
              'If this failed, run supabase/migrations/001_video_standards.sql first.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final standards = widget.data.usaStandards;
    final pbs = SwimAnalytics.personalBests(widget.data.raceLogs);
    final strokes = {
      'All',
      ...standards.map((s) => s.stroke),
    }.toList();

    final filtered = _filterStroke == 'All'
        ? standards
        : standards.where((s) => s.stroke == _filterStroke).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'USA Swimming Standards',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Import motivational time standards and compare your personal bests.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _importing ? null : _importStandards,
          icon: _importing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload),
          label: const Text('Import Seed Standards to Supabase'),
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
              ageGroup: '11-12',
            );
            return Card(
              child: ListTile(
                title: Text('${pb.distance} ${pb.stroke} · ${pb.course}'),
                subtitle: Text('PB: ${SwimTime.fromSeconds(pb.timeSeconds)}'),
                trailing: Text(cut ?? 'Below B'),
              ),
            );
          }),
        const SizedBox(height: 24),
        Text('Standards Table', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...filtered.take(40).map(
              (standard) => Card(
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${standard.ageGroup} ${standard.gender} · '
                    '${standard.distance} ${standard.stroke} · ${standard.course}',
                  ),
                  trailing: Text(
                    '${standard.standardLevel} '
                    '${SwimTime.fromSeconds(standard.timeSeconds)}',
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
