import '../../data/models/usa_time_standard.dart';
import '../../data/repositories/swimiq_repository.dart';
import '../utils/swim_stroke_utils.dart';
import 'usa_motivational_standards_catalog.dart';

class UsaStandardsService {
  UsaStandardsService(this._repository);

  final SwimIqRepository _repository;

  Future<UsaMotivationalStandardsCatalog> loadMotivationalCatalog() {
    return UsaMotivationalStandardsCatalog.loadFromAssets();
  }

  Future<List<UsaTimeStandard>> loadBundledStandards() async {
    final catalog = await loadMotivationalCatalog();
    return catalog.flatStandards;
  }

  @Deprecated('Use loadBundledStandards / motivational catalog instead')
  Future<List<UsaTimeStandard>> loadSeedStandards() => loadBundledStandards();

  Future<int> importBundledToSupabase() async {
    final standards = await loadBundledStandards();
    return _repository.upsertUsaStandards(standards);
  }

  Future<int> importSeedToSupabase() => importBundledToSupabase();

  static String? highestCutForTime({
    required List<UsaTimeStandard> standards,
    required String stroke,
    required int distance,
    required String course,
    required double swimmerTime,
    String? ageGroup,
    String? gender,
  }) {
    final canonicalStroke = SwimStrokeUtils.canonical(stroke);
    final matches = standards.where(
      (standard) =>
          SwimStrokeUtils.canonical(standard.stroke) == canonicalStroke &&
          standard.distance == distance &&
          standard.course == course &&
          swimmerTime <= standard.timeSeconds &&
          (ageGroup == null ||
              UsaMotivationalStandardsCatalog.normalizeAgeGroup(
                    standard.ageGroup,
                  ) ==
                  UsaMotivationalStandardsCatalog.normalizeAgeGroup(
                    ageGroup,
                  )) &&
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
