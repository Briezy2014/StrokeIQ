import 'swim_stroke_utils.dart';

class SwimEventParts {
  const SwimEventParts({
    required this.distance,
    required this.stroke,
  });

  final int distance;
  final String stroke;
}

class SwimEventParser {
  SwimEventParser._();

  static SwimEventParts? parse(String event) {
    final trimmed = event.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(trimmed);
    if (match == null) return null;

    final distance = int.tryParse(match.group(1)!);
    final strokeText = match.group(2)?.trim();
    if (distance == null || strokeText == null || strokeText.isEmpty) {
      return null;
    }

    final stroke = SwimStrokeUtils.canonical(strokeText);
    if (stroke.isEmpty) return null;

    return SwimEventParts(distance: distance, stroke: stroke);
  }
}
