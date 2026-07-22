import '../constants/app_constants.dart';
import 'swim_event_options.dart';
import 'swim_stroke_utils.dart';
import 'swim_time.dart';

/// One AI-extracted personal-best row from a Best Times History photo.
class ExtractedBestTimeRow {
  const ExtractedBestTimeRow({
    required this.eventRaw,
    required this.timeRaw,
    this.course,
    this.date,
    this.meetName,
  });

  final String eventRaw;
  final String timeRaw;
  final String? course;
  final String? date;
  final String? meetName;

  factory ExtractedBestTimeRow.fromJson(Map<String, dynamic> json) {
    return ExtractedBestTimeRow(
      eventRaw: (json['event'] ?? '').toString(),
      timeRaw: (json['time'] ?? '').toString(),
      course: json['course']?.toString(),
      date: json['date']?.toString(),
      meetName: (json['meet_name'] ?? json['meetName'])?.toString(),
    );
  }
}

class BestTimesExtractResponse {
  const BestTimesExtractResponse({
    required this.times,
    this.detectedCourse,
    this.notes,
  });

  final List<ExtractedBestTimeRow> times;
  final String? detectedCourse;
  final String? notes;

  factory BestTimesExtractResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['times'];
    final times = <ExtractedBestTimeRow>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          times.add(
            ExtractedBestTimeRow.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return BestTimesExtractResponse(
      times: times,
      detectedCourse: json['detected_course']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

/// Maps OCR/AI event labels like "50 Fly" onto SwimIQ event options.
abstract final class BestTimesEventParser {
  static String? normalizeCourse(String? raw) {
    final text = (raw ?? '').trim().toUpperCase();
    if (text.isEmpty) return null;
    if (text == 'Y' ||
        text == 'SCY' ||
        text.contains('YARD') ||
        text == 'SHORT COURSE YARDS') {
      return 'SCY';
    }
    if (text == 'L' ||
        text == 'LCM' ||
        text.contains('LONG COURSE') ||
        text == 'METERS') {
      return 'LCM';
    }
    if (text == 'S' || text == 'SCM' || text.contains('SHORT COURSE METER')) {
      return 'SCM';
    }
    if (AppConstants.courses.contains(text)) return text;
    return null;
  }

  static double? parseTimeSeconds(String raw) {
    final cleaned = raw
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[YLS]$'), '');
    if (!SwimTime.isValid(cleaned)) return null;
    try {
      return SwimTime.toSeconds(cleaned);
    } on FormatException {
      return null;
    }
  }

  static DateTime? parseDate(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    final match = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})').firstMatch(text);
    if (match == null) return DateTime.tryParse(text);
    final month = int.tryParse(match.group(1)!);
    final day = int.tryParse(match.group(2)!);
    var year = int.tryParse(match.group(3)!);
    if (month == null || day == null || year == null) return null;
    if (year < 100) year += 2000;
    return DateTime(year, month, day);
  }

  static ({int? distance, String? stroke}) parseEventParts(String raw) {
    final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    final match = RegExp(
      r'^(\d{2,4})\s*(FREE|FREESTYLE|BACK|BACKSTROKE|BREAST|BREASTSTROKE|FLY|BUTTERFLY|IM|MEDLEY)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return (distance: null, stroke: null);
    }
    final distance = int.tryParse(match.group(1)!);
    final stroke = _canonicalStroke(match.group(2)!);
    return (distance: distance, stroke: stroke);
  }

  static SwimEventOption? matchOption({
    required String eventRaw,
    required String course,
    required List<SwimEventOption> options,
  }) {
    final parts = parseEventParts(eventRaw);
    if (parts.distance == null || parts.stroke == null) return null;
    final normalizedCourse = normalizeCourse(course) ?? course.toUpperCase();
    for (final option in options) {
      if (option.distance == parts.distance &&
          option.stroke == parts.stroke &&
          option.course.toUpperCase() == normalizedCourse) {
        return option;
      }
    }
    // Fallback: same distance/stroke ignoring course mismatch in option list.
    for (final option in options) {
      if (option.distance == parts.distance && option.stroke == parts.stroke) {
        return SwimEventOption(
          distance: option.distance,
          stroke: option.stroke,
          course: normalizedCourse,
          label: option.label,
        );
      }
    }
    if (parts.distance != null && parts.stroke != null) {
      final label = parts.stroke == 'IM'
          ? '${parts.distance} IM'
          : '${parts.distance} ${parts.stroke}';
      return SwimEventOption(
        distance: parts.distance!,
        stroke: parts.stroke!,
        course: normalizedCourse,
        label: label,
      );
    }
    return null;
  }

  static String _canonicalStroke(String raw) {
    final lower = raw.trim().toLowerCase();
    switch (lower) {
      case 'fly':
      case 'butterfly':
        return 'Butterfly';
      case 'back':
      case 'backstroke':
        return 'Backstroke';
      case 'breast':
      case 'breaststroke':
        return 'Breaststroke';
      case 'free':
      case 'freestyle':
        return 'Freestyle';
      case 'im':
      case 'medley':
        return 'IM';
      default:
        final canonical = SwimStrokeUtils.canonical(raw);
        return canonical.isEmpty ? raw : canonical;
    }
  }
}
