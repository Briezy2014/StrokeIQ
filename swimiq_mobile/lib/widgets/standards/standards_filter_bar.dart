import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/age_group_resolver.dart';
import '../../models/swim_course.dart';
import '../../models/swim_gender.dart';
import '../../providers/standards_providers.dart';

class StandardsFilterBar extends ConsumerWidget {
  const StandardsFilterBar({
    super.key,
    this.showAgeGroup = true,
  });

  final bool showAgeGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCourse = ref.watch(selectedStandardsCourseProvider);
    final selectedGender = ref.watch(selectedStandardsGenderProvider);
    final ageGroup = ref.watch(resolvedAgeGroupProvider);
    final selectedAgeGroup = ref.watch(selectedAgeGroupProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAgeGroup) ...[
              Text(
                'Age group: ${ageGroup ?? 'Add birthday to profile'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AgeGroupResolver.groups.map((group) {
                  final isSelected = (selectedAgeGroup ?? ageGroup) == group;
                  return ChoiceChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedAgeGroupProvider.notifier).state = group;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Text('Course', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<SwimCourse>(
              segments: SwimCourse.values
                  .map(
                    (course) => ButtonSegment(
                      value: course,
                      label: Text(course.code),
                    ),
                  )
                  .toList(),
              selected: {selectedCourse},
              onSelectionChanged: (selection) {
                ref.read(selectedStandardsCourseProvider.notifier).state =
                    selection.first;
              },
            ),
            const SizedBox(height: 12),
            Text('Gender', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<SwimGender>(
              segments: SwimGender.values
                  .map(
                    (gender) => ButtonSegment(
                      value: gender,
                      label: Text(gender.label),
                    ),
                  )
                  .toList(),
              selected: {selectedGender},
              onSelectionChanged: (selection) {
                ref.read(selectedStandardsGenderProvider.notifier).state =
                    selection.first;
              },
            ),
          ],
        ),
      ),
    );
  }
}
