/// Infers stroke, distance, and course from a swim video title or filename.
class VideoEventInference {
  VideoEventInference._();

  static ({String? stroke, int? distance, String? course}) fromTitle(
    String? title,
  ) {
    final text = title?.trim() ?? '';
    if (text.isEmpty) {
      return (stroke: null, distance: null, course: null);
    }

    final lower = text.toLowerCase();
    String? stroke;
    if (lower.contains('fly') || lower.contains('butterfly')) {
      stroke = 'Butterfly';
    } else if (lower.contains('free') || lower.contains('freestyle')) {
      stroke = 'Freestyle';
    } else if (lower.contains('back')) {
      stroke = 'Backstroke';
    } else if (lower.contains('breast')) {
      stroke = 'Breaststroke';
    } else if (RegExp(r'\bim\b').hasMatch(lower)) {
      stroke = 'IM';
    }

    int? distance;
    final distanceMatch = RegExp(r'\b(\d{2,4})\b').firstMatch(lower);
    if (distanceMatch != null) {
      distance = int.tryParse(distanceMatch.group(1)!);
    }

    String? course;
    if (RegExp(r'\blcm\b').hasMatch(lower)) {
      course = 'LCM';
    } else if (RegExp(r'\bscm\b').hasMatch(lower)) {
      course = 'SCM';
    } else if (RegExp(r'\bscy\b').hasMatch(lower)) {
      course = 'SCY';
    } else if (lower.contains('.mov') || lower.contains('denison')) {
      // Aspyn 50 fly race footage defaults to LCM unless specified.
      course = 'LCM';
    }

    return (stroke: stroke, distance: distance, course: course);
  }
}
