import '../../data/models/swimmer_profile.dart';
import '../constants/app_constants.dart';
import '../services/usa_motivational_standards_catalog.dart';
import 'swim_stroke_utils.dart';
import 'swimiq_age_group.dart';
import 'swimiq_gender.dart';

/// One selectable swim event for meet-result logging.
class SwimEventOption {
  const SwimEventOption({
    required this.distance,
    required this.stroke,
    required this.course,
    required this.label,
  });

  final int distance;
  final String stroke;
  final String course;

  /// Display label, e.g. "100 Butterfly".
  final String label;

  String get meetResultEvent => label;
}

/// Builds event dropdown choices from USA motivational standards.
abstract final class SwimEventOptions {
  static const _strokeOrder = [
    'Butterfly',
    'Backstroke',
    'Breaststroke',
    'Freestyle',
    'IM',
  ];

  static List<SwimEventOption> forProfile({
    required UsaMotivationalStandardsCatalog catalog,
    SwimmerProfile? profile,
    String course = 'SCY',
  }) {
    final ageGroup =
        SwimIqAgeGroup.fromProfileOrNull(profile) ?? AppConstants.ageGroups[2];
    final gender =
        SwimIqGender.standardsGenderOrNull(profile) ?? AppConstants.genders.first;
    final normalizedCourse = course.toUpperCase();

    final matches = catalog.search(
      ageGroup: ageGroup,
      gender: gender,
      course: normalizedCourse,
    );

    final seen = <String>{};
    final options = <SwimEventOption>[];

    for (final event in matches) {
      final label = _labelFor(distance: event.distance, stroke: event.stroke);
      final key = '$normalizedCourse|$label';
      if (!seen.add(key)) continue;
      options.add(
        SwimEventOption(
          distance: event.distance,
          stroke: event.stroke,
          course: normalizedCourse,
          label: label,
        ),
      );
    }

    options.sort((a, b) {
      final distanceCompare = a.distance.compareTo(b.distance);
      if (distanceCompare != 0) return distanceCompare;
      return _strokeOrder
          .indexOf(a.stroke)
          .compareTo(_strokeOrder.indexOf(b.stroke));
    });

    return options;
  }

  static String _labelFor({required int distance, required String stroke}) {
    final canonical = SwimStrokeUtils.canonical(stroke);
    if (canonical == 'IM') return '$distance IM';
    return '$distance $canonical';
  }
}
