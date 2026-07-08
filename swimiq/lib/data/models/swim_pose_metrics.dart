/// On-device pose metrics from MediaPipe-compatible BlazePose (33 landmarks).
class SwimPoseMetrics {
  const SwimPoseMetrics({
    required this.engine,
    required this.framesSampled,
    required this.framesWithPose,
    this.avgBodyLineAngleDeg,
    this.hipDropDegrees,
    this.headLiftScore,
    this.avgElbowAngleDeg,
    this.estimatedStrokeCycles,
    this.kickSymmetryScore,
    this.bodyMechanicsPro,
    this.bodyMechanicsCon,
    this.bodyMechanicsSuggestions = const [],
    this.observations = const [],
  });

  static const engineId = 'mediapipe-blazepose-33';

  final String engine;
  final int framesSampled;
  final int framesWithPose;
  final double? avgBodyLineAngleDeg;
  final double? hipDropDegrees;
  final double? headLiftScore;
  final double? avgElbowAngleDeg;
  final int? estimatedStrokeCycles;
  final double? kickSymmetryScore;
  final String? bodyMechanicsPro;
  final String? bodyMechanicsCon;
  final List<String> bodyMechanicsSuggestions;
  final List<String> observations;

  double get detectionRate =>
      framesSampled == 0 ? 0 : framesWithPose / framesSampled;

  bool get hasUsableMetrics => framesWithPose >= 2;

  Map<String, dynamic> toJson() => {
        'engine': engine,
        'frames_sampled': framesSampled,
        'frames_with_pose': framesWithPose,
        'detection_rate': detectionRate,
        'avg_body_line_angle_deg': avgBodyLineAngleDeg,
        'hip_drop_degrees': hipDropDegrees,
        'head_lift_score': headLiftScore,
        'avg_elbow_angle_deg': avgElbowAngleDeg,
        'estimated_stroke_cycles': estimatedStrokeCycles,
        'kick_symmetry_score': kickSymmetryScore,
        'body_mechanics_pro': bodyMechanicsPro,
        'body_mechanics_con': bodyMechanicsCon,
        'body_mechanics_suggestions': bodyMechanicsSuggestions,
        'observations': observations,
      };

  factory SwimPoseMetrics.fromJson(Map<String, dynamic> json) {
    return SwimPoseMetrics(
      engine: json['engine']?.toString() ?? engineId,
      framesSampled: _asInt(json['frames_sampled']) ?? 0,
      framesWithPose: _asInt(json['frames_with_pose']) ?? 0,
      avgBodyLineAngleDeg: _asDouble(json['avg_body_line_angle_deg']),
      hipDropDegrees: _asDouble(json['hip_drop_degrees']),
      headLiftScore: _asDouble(json['head_lift_score']),
      avgElbowAngleDeg: _asDouble(json['avg_elbow_angle_deg']),
      estimatedStrokeCycles: _asInt(json['estimated_stroke_cycles']),
      kickSymmetryScore: _asDouble(json['kick_symmetry_score']),
      bodyMechanicsPro: json['body_mechanics_pro']?.toString(),
      bodyMechanicsCon: json['body_mechanics_con']?.toString(),
      bodyMechanicsSuggestions: (json['body_mechanics_suggestions'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          const [],
      observations: (json['observations'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

/// One sampled frame of pose landmarks (normalized image coordinates).
class PoseFrameSnapshot {
  const PoseFrameSnapshot({
    required this.timestampSec,
    required this.landmarks,
  });

  final double timestampSec;
  final Map<String, PosePoint> landmarks;
}

class PosePoint {
  const PosePoint({
    required this.x,
    required this.y,
    required this.visibility,
  });

  final double x;
  final double y;
  final double visibility;

  bool get isVisible => visibility >= 0.5;
}
