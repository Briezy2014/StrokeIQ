import '../../data/models/swim_video_analysis.dart';
import '../utils/youth_friendly_analysis.dart';

/// Normalizes analysis sections for display — hides legacy/unwanted blocks.
abstract final class VideoAnalysisPresenter {
  static const hiddenSectionKeys = {
    'quick summary',
    'what the video suggests',
    'what cannot be confirmed yet without frame-by-frame ai',
    'what cannot be confirmed from this angle',
    'specific drills',
  };

  static const legacySectionRenames = {
    'top 3 priorities for the next practice':
        'Top 3 priorities for your next race',
  };

  static const sectionOrder = [
    'Quick pro from this video',
    'Quick con from this video',
    'Goal for your next race',
    'Top 3 priorities for your next race',
    'Dryland focus (strength · mobility · stability)',
    'Estimated time savings',
    'Coach notes for next race',
  ];

  static Map<String, String> visibleSections(SwimVideoAnalysis analysis) {
    final raw = analysis.coachingSections;
    final filtered = <String, String>{};

    for (final entry in raw.entries) {
      final normalizedKey = entry.key.trim();
      final lower = normalizedKey.toLowerCase();
      if (hiddenSectionKeys.contains(lower)) {
        continue;
      }
      if (entry.value.trim().isEmpty) continue;

      final displayKey = legacySectionRenames[lower] ?? normalizedKey;
      filtered[displayKey] = YouthFriendlyAnalysis.sanitize(entry.value);
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

  static String? friendlyDisclaimer(SwimVideoAnalysis analysis) {
    final raw = analysis.disclaimer?.trim();
    if (raw == null || raw.isEmpty) return null;

    final lower = raw.toLowerCase();
    if (lower.contains('v1 report') ||
        lower.contains('not automatic video measurement') ||
        lower.contains('upload notes and video metadata only')) {
      return null;
    }
    return YouthFriendlyAnalysis.sanitize(raw);
  }

  static String? analysisEngineLabel(SwimVideoAnalysis analysis) {
    return switch (analysis.analysisEngine) {
      'swimiq-v2-gemini-mediapipe' => 'Gemini + MediaPipe — frame-by-frame video analysis',
      'swimiq-v2-gemini' => 'Gemini — frame-by-frame video analysis',
      'swimiq-v1-notes-mediapipe' => 'Notes + MediaPipe estimate (Gemini unavailable)',
      'swimiq-v1-notes' => 'Notes-based estimate (Gemini unavailable — see setup guide)',
      _ => null,
    };
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
