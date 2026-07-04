import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/models/usa_time_standard.dart';
import '../../data/repositories/swimiq_repository.dart';

class UsaStandardsService {
  UsaStandardsService(this._repository);

  final SwimIqRepository _repository;

  Future<List<UsaTimeStandard>> loadSeedStandards() async {
    final raw = await rootBundle
        .loadString('assets/data/usa_time_standards_seed.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => UsaTimeStandard.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<int> importSeedToSupabase() async {
    final seed = await loadSeedStandards();
    return _repository.upsertUsaStandards(seed);
  }

  static String? highestCutForTime({
    required List<UsaTimeStandard> standards,
    required String stroke,
    required int distance,
    required String course,
    required double swimmerTime,
    String? ageGroup,
    String? gender,
  }) {
    final matches = standards.where(
      (standard) =>
          standard.stroke == stroke &&
          standard.distance == distance &&
          standard.course == course &&
          swimmerTime <= standard.timeSeconds &&
          (ageGroup == null || standard.ageGroup == ageGroup) &&
          (gender == null || standard.gender == gender),
    );

    if (matches.isEmpty) return null;

    const levelOrder = ['AAAA', 'AAA', 'AA', 'A', 'BB', 'B'];
    final sorted = matches.toList()
      ..sort(
        (a, b) => levelOrder
            .indexOf(a.standardLevel)
            .compareTo(levelOrder.indexOf(b.standardLevel)),
      );
    return sorted.first.standardLevel;
  }
}
