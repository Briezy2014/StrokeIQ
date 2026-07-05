import 'dart:io';
import 'dart:typed_data';

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pose_detection/pose_detection.dart';

import '../../data/models/swim_pose_metrics.dart';
import '../utils/swim_pose_metrics_calculator.dart';

bool get isPoseAnalysisSupported =>
    Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS || Platform.isWindows;

const _landmarkKeys = [
  'nose',
  'leftShoulder',
  'rightShoulder',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
];

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  if (!isPoseAnalysisSupported) return null;

  final tempDir = await getTemporaryDirectory();
  final ext = p.extension(fileName ?? '.mp4');
  final tempPath =
      '${tempDir.path}/swimiq_pose_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.mp4' : ext}';
  final tempFile = File(tempPath);
  await tempFile.writeAsBytes(bytes, flush: true);

  final detector = await PoseDetector.create(
    mode: PoseMode.boxesAndLandmarks,
    landmarkModel: PoseLandmarkModel.full,
  );

  cv.VideoCapture? cap;
  cv.Mat? frame;
  try {
    cap = cv.VideoCapture.fromFile(tempPath);
    if (!cap.isOpened) return null;

    final fps = cap.get(cv.CAP_PROP_FPS);
    final totalFrames = cap.get(cv.CAP_PROP_FRAME_COUNT).toInt();
    final frameStep = _frameStep(totalFrames);
    final snapshots = <PoseFrameSnapshot>[];

    var index = 0;
    while (true) {
      final result = cap.read(m: frame);
      final ok = result.$1;
      frame = result.$2;
      if (!ok || frame.isEmpty) break;

      if (index % frameStep == 0) {
        final poses = await detector.detectFromMat(frame);
        final snapshot = _snapshotFromPose(
          poses.isNotEmpty ? poses.first : null,
          fps > 0 ? index / fps : index / 30.0,
        );
        if (snapshot != null) snapshots.add(snapshot);
        if (snapshots.length >= 16) break;
      }
      index++;
    }

    if (snapshots.isEmpty) {
      return SwimPoseMetrics(
        engine: SwimPoseMetrics.engineId,
        framesSampled: index,
        framesWithPose: 0,
        observations: const [
          'Could not detect a swimmer body in the sampled frames. Try a side-on or clearer camera angle.',
        ],
      );
    }

    final metrics = SwimPoseMetricsCalculator.compute(snapshots);
    return SwimPoseMetrics(
      engine: metrics.engine,
      framesSampled: index,
      framesWithPose: snapshots.length,
      avgBodyLineAngleDeg: metrics.avgBodyLineAngleDeg,
      hipDropDegrees: metrics.hipDropDegrees,
      headLiftScore: metrics.headLiftScore,
      avgElbowAngleDeg: metrics.avgElbowAngleDeg,
      estimatedStrokeCycles: metrics.estimatedStrokeCycles,
      kickSymmetryScore: metrics.kickSymmetryScore,
      observations: metrics.observations,
    );
  } finally {
    cap?.release();
    frame?.dispose();
    await detector.dispose();
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}

int _frameStep(int totalFrames) {
  if (totalFrames <= 0) return 5;
  if (totalFrames <= 120) return 4;
  if (totalFrames <= 300) return 8;
  return (totalFrames / 16).ceil().clamp(4, 30);
}

PoseFrameSnapshot? _snapshotFromPose(Pose? pose, double timestampSec) {
  if (pose == null || !pose.hasLandmarks) return null;

  final landmarks = <String, PosePoint>{};
  for (final key in _landmarkKeys) {
    final type = PoseLandmarkType.values.byName(key);
    final landmark = pose.getLandmark(type);
    if (landmark == null) continue;
    landmarks[key] = PosePoint(
      x: landmark.x,
      y: landmark.y,
      visibility: landmark.visibility,
    );
  }

  if (landmarks.length < 6) return null;

  return PoseFrameSnapshot(
    timestampSec: timestampSec,
    landmarks: landmarks,
  );
}
