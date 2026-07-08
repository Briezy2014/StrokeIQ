import '../../data/models/swim_video_analysis.dart';
import '../utils/youth_friendly_analysis.dart';

/// Normalizes analysis sections for display — hides legacy/unwanted blocks.
abstract final class VideoAnalysisPresenter {
  static const hiddenSectionKeys = {
    'what the video suggests',
    'what cannot be confirmed yet without frame-by-frame ai',
    'what cannot be confirmed from this angle',
    'specific drills',
  };

  static const sectionOrder = [
    'Quick Summary',
    'Quick pro from this video',
    'Quick con from this video',
    'Goal for your next race',
    'Top 3 priorities for the next practice',
    'Dryland focus (strength · mobility · stability)',
    'Estimated time savings',
    'Coach notes for next race',
  ];

  static Map<String, String> visibleSections(SwimVideoAnalysis analysis) {
    final raw = analysis.coachingSections;
    final filtered = <String, String>{};

    for (final entry in raw.entries) {
      if (hiddenSectionKeys.contains(entry.key.trim().toLowerCase())) {
        continue;
      }
      if (entry.value.trim().isEmpty) continue;
      filtered[entry.key] = YouthFriendlyAnalysis.sanitize(entry.value);
    }

    final ordered = <String, String>{};
    for (final key in sectionOrder) {
      if (filtered.containsKey(key)) {
        ordered[key] = filtered[key]!;
        filtered.remove(key);
      }
    }
    ordered.addAll(filtered);
    return ordered;
  }

  static String coachNotes(SwimVideoAnalysis analysis) {
    final fromSection = analysis.coachingSections['Coach notes for next race'];
    if (fromSection != null && fromSection.trim().isNotEmpty) {
      return fromSection.trim();
    }
    final raw = analysis.analysisJson?['coach_notes_for_next_race'];
    return raw?.toString().trim() ?? '';
  }

  static SwimVideoAnalysis withCoachNotes(
    SwimVideoAnalysis analysis,
    String notes,
  ) {
    final json = Map<String, dynamic>.from(analysis.analysisJson ?? {});
    final sections = Map<String, dynamic>.from(
      json['sections'] is Map ? json['sections'] as Map : {},
    );
    sections['Coach notes for next race'] = notes;
    json['sections'] = sections;
    json['coach_notes_for_next_race'] = notes;
    return analysis.copyWith(analysisJson: json);
  }
}
