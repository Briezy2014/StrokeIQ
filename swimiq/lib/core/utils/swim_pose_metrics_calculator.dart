import 'dart:math' as math;

import '../../data/models/swim_pose_metrics.dart';

/// Pure-Dart swim metrics from BlazePose / MediaPipe-compatible landmarks.
class SwimPoseMetricsCalculator {
  static SwimPoseMetrics compute(List<PoseFrameSnapshot> frames) {
    if (frames.isEmpty) {
      return const SwimPoseMetrics(
        engine: SwimPoseMetrics.engineId,
        framesSampled: 0,
        framesWithPose: 0,
        observations: ['No pose frames were sampled from the video.'],
      );
    }

    final bodyLineAngles = <double>[];
    final hipDrops = <double>[];
    final headLiftScores = <double>[];
    final elbowAngles = <double>[];
    final leftAnkleY = <double>[];
    final rightAnkleY = <double>[];
    final wristY = <double>[];

    for (final frame in frames) {
      final leftShoulder = frame.landmarks['leftShoulder'];
      final rightShoulder = frame.landmarks['rightShoulder'];
      final leftHip = frame.landmarks['leftHip'];
      final rightHip = frame.landmarks['rightHip'];
      final nose = frame.landmarks['nose'];
      final leftElbow = frame.landmarks['leftElbow'];
      final leftWrist = frame.landmarks['leftWrist'];
      final rightElbow = frame.landmarks['rightElbow'];
      final rightWrist = frame.landmarks['rightWrist'];
      final leftAnkle = frame.landmarks['leftAnkle'];
      final rightAnkle = frame.landmarks['rightAnkle'];

      if (leftShoulder != null &&
          rightShoulder != null &&
          leftHip != null &&
          rightHip != null &&
          leftShoulder.isVisible &&
          rightShoulder.isVisible &&
          leftHip.isVisible &&
          rightHip.isVisible) {
        final shoulderMid = _midpoint(leftShoulder, rightShoulder);
        final hipMid = _midpoint(leftHip, rightHip);
        bodyLineAngles.add(_angleFromHorizontal(shoulderMid, hipMid));
        hipDrops.add((leftHip.y - rightHip.y).abs() * 100);

        if (nose != null && nose.isVisible) {
          final shoulderLineY = (leftShoulder.y + rightShoulder.y) / 2;
          headLiftScores.add(((nose.y - shoulderLineY).abs() * 100).clamp(0, 100));
        }
      }

      for (final triple in [
        (leftElbow, leftShoulder, leftWrist),
        (rightElbow, rightShoulder, rightWrist),
      ]) {
        final elbow = triple.$1;
        final shoulder = triple.$2;
        final wrist = triple.$3;
        if (elbow == null || shoulder == null || wrist == null) continue;
        if (!elbow.isVisible || !shoulder.isVisible || !wrist.isVisible) {
          continue;
        }
        elbowAngles.add(_jointAngle(shoulder, elbow, wrist));
      }

      final visibleWrists = [leftWrist, rightWrist].whereType<PosePoint>().where((p) => p.isVisible);
      if (visibleWrists.isNotEmpty) {
        wristY.add(visibleWrists.map((p) => p.y).reduce((a, b) => a + b) / visibleWrists.length);
      }

      if (leftAnkle != null && leftAnkle.isVisible) leftAnkleY.add(leftAnkle.y);
      if (rightAnkle != null && rightAnkle.isVisible) rightAnkleY.add(rightAnkle.y);
    }

    final observations = <String>[
      'Pose detected in ${frames.length} sampled frame(s).',
    ];

    final avgBodyLine = _average(bodyLineAngles);
    if (avgBodyLine != null) {
      observations.add(
        avgBodyLine.abs() <= 8
            ? 'Body line stays relatively flat on average (${avgBodyLine.toStringAsFixed(1)}°).'
            : 'Body line averages ${avgBodyLine.toStringAsFixed(1)}° — check hips staying near the surface.',
      );
    }

    final avgHipDrop = _average(hipDrops);
    if (avgHipDrop != null && avgHipDrop > 4) {
      observations.add('Hip drop detected (avg ${avgHipDrop.toStringAsFixed(1)}).');
    }

    final strokeCycles = _countPeaks(wristY);
    if (strokeCycles > 0) {
      observations.add('Estimated $strokeCycles arm-cycle peaks in the sampled clip.');
    }

    final kickSymmetry = _kickSymmetry(leftAnkleY, rightAnkleY);

    return SwimPoseMetrics(
      engine: SwimPoseMetrics.engineId,
      framesSampled: frames.length,
      framesWithPose: frames.length,
      avgBodyLineAngleDeg: avgBodyLine,
      hipDropDegrees: avgHipDrop,
      headLiftScore: _average(headLiftScores),
      avgElbowAngleDeg: _average(elbowAngles),
      estimatedStrokeCycles: strokeCycles > 0 ? strokeCycles : null,
      kickSymmetryScore: kickSymmetry,
      observations: observations,
    );
  }

  static PosePoint _midpoint(PosePoint a, PosePoint b) {
    return PosePoint(
      x: (a.x + b.x) / 2,
      y: (a.y + b.y) / 2,
      visibility: math.min(a.visibility, b.visibility),
    );
  }

  static double _angleFromHorizontal(PosePoint top, PosePoint bottom) {
    final dx = bottom.x - top.x;
    final dy = bottom.y - top.y;
    final radians = math.atan2(dy, dx);
    return radians * 180 / math.pi;
  }

  static double _jointAngle(PosePoint a, PosePoint b, PosePoint c) {
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;
    final dot = baX * bcX + baY * bcY;
    final mag = math.sqrt((baX * baX + baY * baY) * (bcX * bcX + bcY * bcY));
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1, 1)) * 180 / math.pi;
  }

  static double? _average(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static int _countPeaks(List<double> values) {
    if (values.length < 3) return 0;
    var peaks = 0;
    for (var i = 1; i < values.length - 1; i++) {
      final prev = values[i - 1];
      final curr = values[i];
      final next = values[i + 1];
      if (curr < prev && curr < next) peaks++;
    }
    return peaks;
  }

  static double? _kickSymmetry(List<double> left, List<double> right) {
    if (left.length < 2 || right.length < 2) return null;
    final leftRange = _range(left);
    final rightRange = _range(right);
    if (leftRange == 0 && rightRange == 0) return 100;
    final maxRange = math.max(leftRange, rightRange);
    if (maxRange == 0) return 100;
    final diff = (leftRange - rightRange).abs();
    return (100 - (diff / maxRange) * 100).clamp(0, 100);
  }

  static double _range(List<double> values) {
    return values.reduce(math.max) - values.reduce(math.min);
  }
}
