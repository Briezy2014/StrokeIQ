import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/swim_pose_metrics_calculator.dart';
import 'package:swimiq/data/models/swim_pose_metrics.dart';

void main() {
  group('SwimPoseMetricsCalculator', () {
    test('computes body line and stroke cycle observations', () {
      final frames = List.generate(6, (index) {
        final yShift = index.isEven ? 0.0 : 0.03;
        return PoseFrameSnapshot(
          timestampSec: index.toDouble(),
          landmarks: {
            'leftShoulder': PosePoint(x: 0.4, y: 0.3, visibility: 0.9),
            'rightShoulder': PosePoint(x: 0.6, y: 0.3, visibility: 0.9),
            'leftHip': PosePoint(x: 0.42, y: 0.5 + yShift, visibility: 0.9),
            'rightHip': PosePoint(x: 0.58, y: 0.5, visibility: 0.9),
            'leftWrist': PosePoint(x: 0.35, y: 0.35 + yShift, visibility: 0.9),
            'rightWrist': PosePoint(x: 0.65, y: 0.35, visibility: 0.9),
            'leftAnkle': PosePoint(x: 0.43, y: 0.8 + yShift, visibility: 0.9),
            'rightAnkle': PosePoint(x: 0.57, y: 0.8, visibility: 0.9),
            'nose': PosePoint(x: 0.5, y: 0.25, visibility: 0.9),
          },
        );
      });

      final metrics = SwimPoseMetricsCalculator.compute(frames);

      expect(metrics.framesWithPose, 6);
      expect(metrics.avgBodyLineAngleDeg, isNotNull);
      expect(metrics.estimatedStrokeCycles, greaterThan(0));
      expect(metrics.observations, isNotEmpty);
    });
  });
}
