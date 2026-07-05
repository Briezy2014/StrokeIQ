import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../core/utils/swimiq_gender.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../core/utils/swim_time.dart';
import '../../providers/app_providers.dart';
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
  bool _uploading = false;
  final _searchController = TextEditingController();
  String? _selectedAgeGroup;
  String? _selectedGender;
  String? _selectedCourse;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadStandardsFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected JSON file.')),
      );
      return;
    }

    setState(() => _uploading = true);
    final raw = String.fromCharCodes(file.bytes!);
    final error = await ref
        .read(usaMotivationalStandardsCatalogProvider.notifier)
        .loadFromJsonString(raw);

    if (!mounted) return;
    setState(() => _uploading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await ref.read(swimmerDataProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Loaded ${file.name}. USA cuts now use this standards file.',
        ),
      ),
    );
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
        final profileReady = SwimIqStandardsProfile.isReady(data.profile);
        final ageGroup = SwimIqAgeGroup.fromProfileOrNull(data.profile);
        final gender = SwimIqGender.standardsGenderOrNull(data.profile);

        if (profileReady) {
          _selectedAgeGroup ??= ageGroup;
          _selectedGender ??= gender;
        } else {
          _selectedAgeGroup ??= AppConstants.ageGroups[2];
          _selectedGender ??= AppConstants.genders.first;
        }

        final results = catalog.search(
          ageGroup: _selectedAgeGroup,
          gender: _selectedGender,
          course: _selectedCourse,
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
            if (!profileReady) ...[
              const SizedBox(height: 12),
              const SwimIqStandardsSetupBanner(),
            ],
            const SizedBox(height: 8),
            Text(
              'Valid through ${catalog.bundle.effectiveThrough}. '
              '${catalog.events.length} official events · '
              'Girls & Boys · SCY / SCM / LCM · '
              'Age brackets: ${AppConstants.ageGroups.join(', ')}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a new USA Swimming JSON export each season to refresh cuts '
              'without waiting for an app update.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SwimIqSaveButton(
              label: 'Upload New Standards JSON',
              isSaving: _uploading,
              onPressed: _uploadStandardsFile,
            ),
            const SizedBox(height: 12),
            SwimIqSaveButton(
              label: 'Sync Current Standards to Supabase',
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
            Text('Age group', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.ageGroups.map((group) {
                return FilterChip(
                  label: Text(group),
                  selected: _selectedAgeGroup == group,
                  onSelected: (_) => setState(() => _selectedAgeGroup = group),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text('Gender', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.genders.map((value) {
                return FilterChip(
                  label: Text(value),
                  selected: _selectedGender == value,
                  onSelected: (_) => setState(() => _selectedGender = value),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text('Course', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCourse == null,
                  onSelected: (_) => setState(() => _selectedCourse = null),
                ),
                ...AppConstants.courses.map((course) {
                  return FilterChip(
                    label: Text(course),
                    selected: _selectedCourse == course,
                    onSelected: (_) => setState(() => _selectedCourse = course),
                  );
                }),
              ],
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
                  ageGroup: _selectedAgeGroup ?? ageGroup,
                  gender: _selectedGender ?? gender,
                );
                return SwimIqEventListTile(
                  title: '${pb.distance} ${pb.stroke} · ${pb.course}',
                  subtitle:
                      '${_selectedAgeGroup ?? ageGroup ?? '—'} · ${_selectedGender ?? gender ?? '—'} · ${cut ?? 'Below B'} motivational cut',
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
