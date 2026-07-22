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

    final avgBodyLine = _average(bodyLineAngles);
    final avgHipDrop = _average(hipDrops);
    final avgHeadLift = _average(headLiftScores);
    final avgElbow = _average(elbowAngles);
    final strokeCycles = _countPeaks(wristY);
    final kickSymmetry = _kickSymmetry(leftAnkleY, rightAnkleY);

    final coaching = _buildBodyMechanicsCoaching(
      avgBodyLine: avgBodyLine,
      avgHipDrop: avgHipDrop,
      avgHeadLift: avgHeadLift,
      avgElbow: avgElbow,
      kickSymmetry: kickSymmetry,
      strokeCycles: strokeCycles,
      framesWithPose: frames.length,
    );

    return SwimPoseMetrics(
      engine: SwimPoseMetrics.engineId,
      framesSampled: frames.length,
      framesWithPose: frames.length,
      avgBodyLineAngleDeg: avgBodyLine,
      hipDropDegrees: avgHipDrop,
      headLiftScore: avgHeadLift,
      avgElbowAngleDeg: avgElbow,
      estimatedStrokeCycles: strokeCycles > 0 ? strokeCycles : null,
      kickSymmetryScore: kickSymmetry,
      bodyMechanicsPro: coaching.pro,
      bodyMechanicsCon: coaching.con,
      bodyMechanicsSuggestions: coaching.suggestions,
      observations: coaching.observations,
    );
  }

  static _BodyMechanicsCoaching _buildBodyMechanicsCoaching({
    required double? avgBodyLine,
    required double? avgHipDrop,
    required double? avgHeadLift,
    required double? avgElbow,
    required double? kickSymmetry,
    required int strokeCycles,
    required int framesWithPose,
  }) {
    final observations = <String>[
      'MediaPipe sampled $framesWithPose frame(s) and tracked shoulder, hip, head, elbow, and ankle landmarks.',
    ];
    final suggestions = <String>[];
    String? pro;
    String? con;

    if (avgBodyLine != null) {
      final angle = avgBodyLine.abs();
      observations.add(
        'Body line angle (shoulder-to-hip): ${angle.toStringAsFixed(1)}° '
        '(0° = flat streamline; higher = hips or chest out of alignment).',
      );
      if (angle <= 8) {
        pro = 'Flat body line (${angle.toStringAsFixed(1)}°) — hips and chest stay aligned near the surface, '
            'which helps you carry speed between strokes.';
      } else {
        con = 'Body line averages ${angle.toStringAsFixed(1)}° — hips are likely sitting below the shoulders. '
            'Think "hips up, chest slightly down" to stay long on the water.';
        suggestions.add(
          'Press your chest slightly down and lift your hips toward the surface so shoulder, hip, and ankle line up.',
        );
      }
    }

    if (avgHipDrop != null) {
      observations.add(
        'Hip drop asymmetry: ${avgHipDrop.toStringAsFixed(1)} '
        '(lower = even hips; higher = one hip sinking below the other).',
      );
      if (avgHipDrop > 4) {
        con ??= 'Hips are dropping below the body line (asymmetry ${avgHipDrop.toStringAsFixed(1)}). '
            'Sinking hips create drag — drive the kick from the hips and keep the core tight.';
        suggestions.add(
          'Keep hips high near the surface: tighten your core, kick from the hips (not just the knees), '
          'and avoid letting the lower body "sit" in the water.',
        );
      } else if (pro == null) {
        pro = 'Hips stay relatively even near the surface (drop ${avgHipDrop.toStringAsFixed(1)}) — '
            'good body position for holding a long streamline.';
      }
    }

    if (avgHeadLift != null) {
      observations.add(
        'Head lift score: ${avgHeadLift.toStringAsFixed(1)} '
        '(lower = head down in line with shoulders; higher = head lifting and pulling hips down).',
      );
      if (avgHeadLift > 12) {
        final headCon =
            'Head lifts above the shoulder line (score ${avgHeadLift.toStringAsFixed(1)}). '
            'When the head comes up, the hips usually drop — keep the head down and eyes looking at the bottom during streamline and breathing.';
        con = con == null ? headCon : '$con $headCon';
        suggestions.add(
          'Head down, hips up: look at the bottom of the pool between breaths and keep one goggle in the water when you breathe.',
        );
      } else if (pro == null || pro.contains('body line')) {
        pro = pro ??
            'Head stays low relative to the shoulders (${avgHeadLift.toStringAsFixed(1)}) — '
                'this helps keep hips up and reduces frontal drag.';
      }
    }

    if (avgElbow != null) {
      observations.add(
        'Average elbow angle at the arm: ${avgElbow.toStringAsFixed(1)}° '
        '(early catch often lands near 90–120° depending on stroke).',
      );
      if (avgElbow < 70) {
        suggestions.add(
          'Elbow is staying quite straight (${avgElbow.toStringAsFixed(1)}°) — aim for a higher elbow on the catch so you pull water with the forearm and hand, not just reach.',
        );
      } else if (avgElbow > 150) {
        suggestions.add(
          'Elbow angle is very open (${avgElbow.toStringAsFixed(1)}°) — set the catch sooner so the forearm presses back on the water instead of slipping through.',
        );
      } else {
        if (pro == null) {
          pro = 'Elbow angle (${avgElbow.toStringAsFixed(1)}°) looks in a workable range for an early catch and pull.';
        }
      }
    }

    if (kickSymmetry != null) {
      observations.add(
        'Kick symmetry: ${kickSymmetry.toStringAsFixed(0)}/100 '
        '(100 = even left/right kick amplitude).',
      );
      if (kickSymmetry < 70) {
        final kickCon =
            'Kick symmetry is ${kickSymmetry.toStringAsFixed(0)}/100 — one side may be kicking stronger or deeper than the other.';
        con = con == null ? kickCon : '$con $kickCon';
        suggestions.add(
          'Balance the kick: equal amplitude left and right, initiate from the hips, and keep ankles relaxed but quick.',
        );
      } else if (pro == null) {
        pro = 'Kick symmetry is ${kickSymmetry.toStringAsFixed(0)}/100 — left and right legs are working evenly.';
      }
    }

    if (strokeCycles > 0) {
      observations.add('Estimated $strokeCycles arm-cycle peaks in the sampled clip.');
    }

    if (suggestions.isEmpty && con != null) {
      suggestions.add('Film from the side at pool-deck height so MediaPipe can track body angles more accurately.');
    }

    if (pro == null && con == null) {
      pro = 'MediaPipe detected usable body landmarks — review the angle notes above with your coach.';
    }

    return _BodyMechanicsCoaching(
      pro: pro,
      con: con,
      suggestions: suggestions,
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

class _BodyMechanicsCoaching {
  const _BodyMechanicsCoaching({
    required this.pro,
    required this.con,
    required this.suggestions,
    required this.observations,
  });

  final String? pro;
  final String? con;
  final List<String> suggestions;
  final List<String> observations;
}
