import 'package:pose_detection/pose_detection.dart';

import '../../data/models/swim_pose_metrics.dart';

/// Maps BlazePose landmarks into SwimIQ pose frame coordinates (0–1 normalized).
abstract final class SwimPoseLandmarkMapper {
  static const _trackedTypes = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  static Map<String, PosePoint> fromPose(
    Pose pose, {
    required double width,
    required double height,
  }) {
    if (width <= 0 || height <= 0) return const {};

    final landmarks = <String, PosePoint>{};
    for (final type in _trackedTypes) {
      final landmark = pose.getLandmark(type);
      if (landmark == null) continue;
      landmarks[type.name] = PosePoint(
        x: landmark.x / width,
        y: landmark.y / height,
        visibility: landmark.visibility,
      );
    }
    return landmarks;
  }
}
