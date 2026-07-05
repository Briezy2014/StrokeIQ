import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:pose_detection/pose_detection.dart';
import 'package:web/web.dart';

import '../../data/models/swim_pose_metrics.dart';
import '../utils/swim_pose_metrics_calculator.dart';

bool get isPoseAnalysisSupported => true;

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
  final detector = await PoseDetector.create(
    mode: PoseMode.boxesAndLandmarks,
    landmarkModel: PoseLandmarkModel.full,
  );

  try {
    final frameBytes = await _sampleJpegFrames(bytes, maxFrames: 12);
    final snapshots = <PoseFrameSnapshot>[];

    for (var i = 0; i < frameBytes.length; i++) {
      final poses = await detector.detect(frameBytes[i]);
      final snapshot = _snapshotFromPose(
        poses.isNotEmpty ? poses.first : null,
        i.toDouble(),
      );
      if (snapshot != null) snapshots.add(snapshot);
    }

    if (snapshots.isEmpty) {
      return SwimPoseMetrics(
        engine: SwimPoseMetrics.engineId,
        framesSampled: frameBytes.length,
        framesWithPose: 0,
        observations: const [
          'Could not detect a swimmer body in the sampled frames. Try a clearer side-on angle.',
        ],
      );
    }

    final metrics = SwimPoseMetricsCalculator.compute(snapshots);
    return SwimPoseMetrics(
      engine: metrics.engine,
      framesSampled: frameBytes.length,
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
    await detector.dispose();
  }
}

Future<List<Uint8List>> _sampleJpegFrames(
  Uint8List videoBytes, {
  required int maxFrames,
}) async {
  final blob = Blob(<JSUint8Array>[videoBytes.toJS].toJS);
  final url = URL.createObjectURL(blob);
  final video = document.createElement('video') as HTMLVideoElement
    ..src = url
    ..muted = true
    ..preload = 'auto';

  await _waitForEvent(video, 'loadedmetadata');

  final duration = video.duration.isFinite ? video.duration : 0;
  final canvas = document.createElement('canvas') as HTMLCanvasElement
    ..width = video.videoWidth
    ..height = video.videoHeight;
  final context = canvas.getContext('2d') as CanvasRenderingContext2D?;

  final frames = <Uint8List>[];
  if (context == null || video.videoWidth == 0) {
    URL.revokeObjectURL(url);
    return frames;
  }

  for (var i = 0; i < maxFrames; i++) {
    final target = duration > 0 ? duration * (i + 1) / (maxFrames + 1) : i * 0.5;
    video.currentTime = target;
    await _waitForEvent(video, 'seeked');
    context.drawImage(video, 0, 0);
    final dataUrl = canvas.toDataURL('image/jpeg');
    frames.add(_dataUrlToBytes(dataUrl));
  }

  URL.revokeObjectURL(url);
  return frames;
}

Future<void> _waitForEvent(EventTarget target, String eventName) {
  final completer = Completer<void>();
  void handler(Event _) {
    target.removeEventListener(eventName, handler.toJS);
    if (!completer.isCompleted) completer.complete();
  }

  target.addEventListener(eventName, handler.toJS);
  return completer.future;
}

Uint8List _dataUrlToBytes(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  final base64Data = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
  return Uint8List.fromList(base64Decode(base64Data));
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
