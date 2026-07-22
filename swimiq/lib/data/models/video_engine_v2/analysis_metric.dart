/// Single validated metric from Video Engine V2.
class AnalysisMetric {
  const AnalysisMetric({
    required this.name,
    required this.displayName,
    this.value,
    this.unit,
    this.confidence,
    this.confidenceLabel = 'unavailable',
    this.classification = 'unavailable',
    this.method,
    this.unavailableReason,
    this.qualityFlags = const [],
    this.supportingFrames = const [],
    this.startMs,
    this.endMs,
  });

  final String name;
  final String displayName;
  final num? value;
  final String? unit;
  final double? confidence;
  final String confidenceLabel;
  final String classification;
  final String? method;
  final String? unavailableReason;
  final List<String> qualityFlags;
  final List<int> supportingFrames;
  final int? startMs;
  final int? endMs;

  bool get isUnavailable =>
      value == null ||
      classification == 'unavailable' ||
      confidenceLabel == 'unavailable';

  bool get isLowConfidence =>
      !isUnavailable &&
      (confidenceLabel == 'low' ||
          (confidence != null && confidence! < 0.65));

  /// Never coerce null to 0. Unavailable metrics show explanation text.
  String get displayValue {
    if (isUnavailable || value == null) {
      return unavailableReason?.trim().isNotEmpty == true
          ? 'Unavailable'
          : '—';
    }
    final v = value!;
    if (v is int || v == v.roundToDouble()) {
      return v is int ? '$v' : '${v.toInt()}';
    }
    return v.toStringAsFixed(1);
  }

  String get displayWithUnit {
    if (isUnavailable || value == null) return displayValue;
    final u = unit?.trim();
    if (u == null || u.isEmpty) return displayValue;
    return '$displayValue $u';
  }

  factory AnalysisMetric.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['metric_id'] ?? 'metric').toString();
    final display =
        (json['display_name'] ?? json['displayName'] ?? name).toString();
    final rawValue = json['value'];
    num? value;
    if (rawValue is num) {
      value = rawValue;
    } else if (rawValue != null) {
      value = num.tryParse(rawValue.toString());
    }

    return AnalysisMetric(
      name: name,
      displayName: display,
      value: value,
      unit: json['unit']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      confidenceLabel:
          (json['confidence_label'] ?? json['confidenceLabel'] ?? 'unavailable')
              .toString(),
      classification:
          (json['classification'] ?? 'unavailable').toString(),
      method: json['method']?.toString(),
      unavailableReason: (json['unavailable_reason'] ??
              json['unavailableReason'])
          ?.toString(),
      qualityFlags: _stringList(json['quality_flags']),
      supportingFrames: _intList(
        json['supporting_frames'] ?? json['supporting_frame_numbers'],
      ),
      startMs: (json['start_ms'] as num?)?.toInt(),
      endMs: (json['end_ms'] as num?)?.toInt(),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  static List<int> _intList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e is num ? e.toInt() : int.tryParse(e.toString()))
        .whereType<int>()
        .toList(growable: false);
  }
}
