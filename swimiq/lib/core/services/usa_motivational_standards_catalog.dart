import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/models/usa_motivational_standard.dart';
import '../../data/models/usa_time_standard.dart';
import '../utils/swim_stroke_utils.dart';

class UsaMotivationalStandardsCatalog {
  UsaMotivationalStandardsCatalog._({
    required this.bundle,
    required this.eventsByKey,
    required this.flatStandards,
  });

  static const assetPath =
      'assets/data/usa_motivational_standards_2024_2028.json';

  static const standardLevels = ['B', 'BB', 'A', 'AA', 'AAA', 'AAAA'];

  final UsaMotivationalStandardsBundle bundle;
  final Map<String, UsaMotivationalEventStandard> eventsByKey;
  final List<UsaTimeStandard> flatStandards;

  String get versionLabel => bundle.versionLabel;
  String get versionId => bundle.versionId;

  /// Empty catalog used when the web build is missing the asset file.
  /// Prefer a full rebuild/republish; this keeps login from hard-failing.
  static UsaMotivationalStandardsCatalog empty() {
    return UsaMotivationalStandardsCatalog._(
      bundle: const UsaMotivationalStandardsBundle(
        versionId: 'missing',
        versionLabel: 'Standards unavailable',
        source: 'asset-missing',
        effectiveThrough: 0,
        events: [],
      ),
      eventsByKey: const {},
      flatStandards: const [],
    );
  }

  static Future<UsaMotivationalStandardsCatalog> loadFromAssets() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final bundle = UsaMotivationalStandardsBundle.fromJson(decoded);
      final eventsByKey = <String, UsaMotivationalEventStandard>{};

      for (final event in bundle.events) {
        eventsByKey[_eventKey(
          ageGroup: event.ageGroup,
          gender: event.gender,
          course: event.course,
          distance: event.distance,
          stroke: event.stroke,
        )] = event;
      }

      final flat = (decoded['flat_standards'] as List? ?? [])
          .map(
            (item) => UsaTimeStandard.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      return UsaMotivationalStandardsCatalog._(
        bundle: bundle,
        eventsByKey: eventsByKey,
        flatStandards: flat,
      );
    } catch (_) {
      // Incomplete GoDaddy/web zip must not block sign-in.
      return empty();
    }
  }

  List<UsaMotivationalEventStandard> get events => bundle.events;

  UsaMotivationalEventStandard? eventFor({
    required String ageGroup,
    required String gender,
    required String stroke,
    required int distance,
    required String course,
  }) {
    return eventsByKey[_eventKey(
      ageGroup: ageGroup,
      gender: gender,
      course: course,
      distance: distance,
      stroke: stroke,
    )];
  }

  List<UsaMotivationalEventStandard> search({
    String? ageGroup,
    String? gender,
    String? course,
    String? stroke,
    String? query,
  }) {
    final normalizedQuery = query?.trim().toLowerCase();
    return events.where((event) {
      if (ageGroup != null &&
          normalizeAgeGroup(ageGroup) != normalizeAgeGroup(event.ageGroup)) {
        return false;
      }
      if (gender != null &&
          !_genderMatches(gender, event.gender)) {
        return false;
      }
      if (course != null && course.toUpperCase() != event.course.toUpperCase()) {
        return false;
      }
      if (stroke != null &&
          SwimStrokeUtils.canonical(stroke) !=
              SwimStrokeUtils.canonical(event.stroke)) {
        return false;
      }
      if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
        final haystack =
            '${event.event} ${event.ageGroup} ${event.gender} ${event.course}'
                .toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }
      return true;
    }).toList();
  }

  String? highestCutForTime({
    required String stroke,
    required int distance,
    required String course,
    required double swimmerTime,
    String? ageGroup,
    String? gender,
  }) {
    final event = eventFor(
      ageGroup: ageGroup ?? '11-12',
      gender: _normalizeGender(gender ?? 'Girls') == 'boys' ? 'Boys' : 'Girls',
      stroke: stroke,
      distance: distance,
      course: course,
    );
    if (event == null) return null;

    for (final level in standardLevels.reversed) {
      final cut = event.cuts[level];
      if (cut != null && swimmerTime <= cut) return level;
    }
    return null;
  }

  String motivationalSummary({
    required String stroke,
    required int distance,
    required String course,
    required double swimmerTime,
    String? ageGroup,
    String? gender,
  }) {
    final cut = highestCutForTime(
      stroke: stroke,
      distance: distance,
      course: course,
      swimmerTime: swimmerTime,
      ageGroup: ageGroup,
      gender: gender,
    );
    return cut ?? 'Below B';
  }

  static String normalizeAgeGroup(String value) {
    final text = value.trim().toLowerCase().replaceAll('  ', ' ');
    if (text == '10 & under' || text == '10 and under') return '10 & under';
    return value.trim();
  }

  static String _eventKey({
    required String ageGroup,
    required String gender,
    required String course,
    required int distance,
    required String stroke,
  }) {
    return [
      normalizeAgeGroup(ageGroup).toLowerCase(),
      gender.trim().toLowerCase(),
      course.trim().toUpperCase(),
      distance,
      SwimStrokeUtils.canonical(stroke).toLowerCase(),
    ].join('|');
  }

  static bool _genderMatches(String left, String right) {
    return _normalizeGender(left) == _normalizeGender(right);
  }

  static String _normalizeGender(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.startsWith('m') ||
        lower.startsWith('b') ||
        lower == 'boy') {
      return 'boys';
    }
    return 'girls';
  }
}
