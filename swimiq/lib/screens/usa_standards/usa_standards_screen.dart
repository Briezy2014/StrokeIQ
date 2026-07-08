import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../core/utils/motivational_cut.dart';
import '../../core/utils/swimiq_age_group.dart';
import '../../core/utils/swimiq_gender.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../core/utils/swim_time.dart';
import '../../widgets/swimiq_event_card.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

class UsaStandardsScreen extends ConsumerStatefulWidget {
  const UsaStandardsScreen({super.key});

  @override
  ConsumerState<UsaStandardsScreen> createState() => _UsaStandardsScreenState();
}

class _UsaStandardsScreenState extends ConsumerState<UsaStandardsScreen> {
  final _searchController = TextEditingController();
  String? _selectedAgeGroup;
  String? _selectedGender;
  String? _selectedCourse;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

        final pbAgeGroup = profileReady ? ageGroup : null;
        final pbGender = profileReady ? gender : null;
        final snapshot = data.passportSnapshot(swimmer);

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
            SwimIqPageHero(
              title: 'USA Standards',
              subtitle: catalog.versionLabel,
              stats: [
                SwimIqHeroStat('${pbs.length} PBs tracked'),
                SwimIqHeroStat(snapshot.highestCut),
              ],
            ),
            const SizedBox(height: 16),
            if (!profileReady) ...[
              const SwimIqStandardsSetupBanner(),
              const SizedBox(height: 12),
            ],
            Text(
              'Valid through ${catalog.bundle.effectiveThrough}. '
              '${catalog.events.length} official events · '
              'Girls & Boys separated · SCY / SCM / LCM courses · '
              'Age brackets: ${AppConstants.ageGroups.join(', ')}.',
              style: Theme.of(context).textTheme.bodySmall,
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
            if (profileReady)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Your cuts use passport age ($ageGroup). Filters below browse the standards table only.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
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
            if (profileReady && pbAgeGroup != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Using your passport: $pbAgeGroup · $pbGender',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            if (!profileReady)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SwimIqStandardsSetupBanner(),
              ),
            if (pbs.isEmpty)
              const EmptyStateMessage(
                message: 'Add training sessions to compare against standards.',
              )
            else
              ...pbs.map((pb) {
                final cut = MotivationalCut.forSwim(
                  catalog: catalog,
                  profile: data.profile,
                  stroke: pb.stroke,
                  distance: pb.distance,
                  course: pb.course,
                  timeSeconds: pb.timeSeconds,
                  ageGroup: pbAgeGroup,
                  gender: pbGender,
                );
                final cutLabel = cut ??
                    (profileReady ? 'Below B' : SwimIqStandardsProfile.setupMessageShort);
                return SwimIqEventCard(
                  title: '${pb.distance} ${pb.stroke} · ${pb.course}',
                  subtitle:
                      '${pb.sourceLabel} · ${pbAgeGroup ?? '—'} · '
                      '${pbGender ?? '—'} · $cutLabel motivational cut',
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
