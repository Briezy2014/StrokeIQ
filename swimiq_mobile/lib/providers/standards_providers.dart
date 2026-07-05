import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/age_group_resolver.dart';
import '../core/constants.dart';
import '../models/motivational_standard.dart';
import '../models/standard_level.dart';
import '../models/swim_course.dart';
import '../models/swim_gender.dart';
import '../services/motivational_standards_repository.dart';
import '../services/standards_analytics.dart';
import 'app_providers.dart';
import 'profile_providers.dart';

final motivationalStandardsRepositoryProvider =
    Provider<MotivationalStandardsRepository>((ref) {
  return MotivationalStandardsRepository(ref.watch(supabaseClientProvider));
});

final standardsVersionProvider = Provider<String>((ref) {
  return AppConstants.defaultStandardsVersion;
});

final selectedStandardsCourseProvider = StateProvider<SwimCourse>(
  (ref) => SwimCourse.scy,
);

final selectedStandardsGenderProvider = StateProvider<SwimGender>(
  (ref) => SwimGender.female,
);

final selectedAgeGroupProvider = StateProvider<String?>((ref) => null);

final resolvedAgeGroupProvider = Provider<String?>((ref) {
  return ref.watch(selectedAgeGroupProvider) ?? ref.watch(swimmerAgeGroupProvider);
});

final selectedGoalLevelProvider = StateProvider<StandardLevel>(
  (ref) => StandardLevel.a,
);

final standardsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(motivationalStandardsRepositoryProvider);
  final version = ref.watch(standardsVersionProvider);
  return repository.countStandards(version: version);
});

final motivationalStandardsProvider =
    FutureProvider.autoDispose<List<MotivationalStandard>>((ref) async {
  final repository = ref.watch(motivationalStandardsRepositoryProvider);
  final version = ref.watch(standardsVersionProvider);
  final course = ref.watch(selectedStandardsCourseProvider);
  final gender = ref.watch(selectedStandardsGenderProvider);
  final ageGroup = ref.watch(resolvedAgeGroupProvider);

  return repository.fetchStandards(
    version: version,
    ageGroup: ageGroup,
    gender: gender.code,
    course: course.code,
  );
});

final filteredStandardsProvider =
    FutureProvider.autoDispose.family<List<MotivationalStandard>, String>(
  (ref, eventQuery) async {
    final repository = ref.watch(motivationalStandardsRepositoryProvider);
    final version = ref.watch(standardsVersionProvider);
    final course = ref.watch(selectedStandardsCourseProvider);
    final gender = ref.watch(selectedStandardsGenderProvider);
    final ageGroup = ref.watch(resolvedAgeGroupProvider);

    return repository.fetchStandards(
      version: version,
      ageGroup: ageGroup,
      gender: gender.code,
      course: course.code,
      eventQuery: eventQuery,
    );
  },
);

final swimmerAgeGroupProvider = Provider<String?>((ref) {
  final profileAsync = ref.watch(swimmerProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) {
      final birthday = profile?.birthday;
      if (birthday == null) {
        return null;
      }
      return AgeGroupResolver.fromBirthday(birthday);
    },
    orElse: () => null,
  );
});

final standardsLoadedProvider = Provider<bool>((ref) {
  final countAsync = ref.watch(standardsCountProvider);
  return countAsync.maybeWhen(data: (count) => count > 0, orElse: () => false);
});

/// Compare a swim time against the shared repository for the active swimmer context.
final standardComparisonProvider = FutureProvider.autoDispose
    .family<StandardComparison?, ({String event, double timeSeconds})>(
  (ref, input) async {
    final repository = ref.watch(motivationalStandardsRepositoryProvider);
    final version = ref.watch(standardsVersionProvider);
    final course = ref.watch(selectedStandardsCourseProvider);
    final gender = ref.watch(selectedStandardsGenderProvider);
    final ageGroup = ref.watch(resolvedAgeGroupProvider);

    if (ageGroup == null) {
      return null;
    }

    final standard = await repository.fetchStandardForEvent(
      ageGroup: ageGroup,
      gender: gender.code,
      course: course.code,
      event: input.event,
      version: version,
    );

    if (standard == null) {
      return null;
    }

    return StandardsAnalytics.compare(
      swimTimeSeconds: input.timeSeconds,
      standard: standard,
    );
  },
);
