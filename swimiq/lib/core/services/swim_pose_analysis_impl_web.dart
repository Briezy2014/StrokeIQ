import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:pose_detection/pose_detection.dart';
import 'package:web/web.dart' as web;

import '../../data/models/swim_pose_metrics.dart';
import '../utils/swim_pose_landmark_mapper.dart';
import '../utils/swim_pose_metrics_calculator.dart';

/// Web builds sample swim video frames in the browser, then run BlazePose.
bool get isPoseAnalysisSupported => true;

const _maxFrames = 16;
const _sampleIntervalSec = 0.5;

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  PoseDetector? detector;
  web.HTMLVideoElement? video;
  String? objectUrl;

  try {
    detector = await PoseDetector.create(
      mode: PoseMode.boxesAndLandmarks,
      landmarkModel: PoseLandmarkModel.full,
    );

    video = web.HTMLVideoElement()
      ..muted = true
      ..playsInline = true
      ..preload = 'auto';

    final blobParts = [bytes.toJS].toJS;
    final mime = _mimeFromFileName(fileName);
    final blob = mime == null
        ? web.Blob(blobParts)
        : web.Blob(blobParts, web.BlobPropertyBag(type: mime));
    objectUrl = web.URL.createObjectURL(blob);
    video.src = objectUrl;

    await _waitForVideoMetadata(video);
    final duration = video.duration;
    if (!duration.isFinite || duration <= 0) {
      return null;
    }

    final width = video.videoWidth.toDouble();
    final height = video.videoHeight.toDouble();
    if (width <= 0 || height <= 0) {
      return null;
    }

    final canvas = web.HTMLCanvasElement()
      ..width = video.videoWidth
      ..height = video.videoHeight;
    final context = canvas.getContext('2d')! as web.CanvasRenderingContext2D;

    final sampleTimes = <double>[];
    for (var t = 0.0; t < duration && sampleTimes.length < _maxFrames; t += _sampleIntervalSec) {
      sampleTimes.add(t);
    }
    if (sampleTimes.isEmpty) {
      sampleTimes.add(0);
    }

    final frames = <PoseFrameSnapshot>[];
    for (final timestampSec in sampleTimes) {
      await _seekVideo(video, timestampSec);
      context.drawImage(video, 0, 0);
      final dataUrl = canvas.toDataURL('image/jpeg', 0.82.toJS);
      final frameBytes = _jpegBytesFromDataUrl(dataUrl);
      if (frameBytes.isEmpty) continue;

      final poses = await detector.detect(frameBytes);
      if (poses.isEmpty) continue;

      final landmarks = SwimPoseLandmarkMapper.fromPose(
        poses.first,
        width: width,
        height: height,
      );
      if (landmarks.isEmpty) continue;

      frames.add(PoseFrameSnapshot(
        timestampSec: timestampSec,
        landmarks: landmarks,
      ));
    }

    if (frames.isEmpty) return null;
    return SwimPoseMetricsCalculator.compute(frames);
  } catch (_) {
    return null;
  } finally {
    video?.pause();
    video?.removeAttribute('src');
    if (objectUrl != null) {
      web.URL.revokeObjectURL(objectUrl);
    }
    await detector?.dispose();
  }
}

Future<void> _waitForVideoMetadata(web.HTMLVideoElement video) async {
  if (video.readyState >= 1) return;

  final completer = Completer<void>();
  void handler(web.Event _) {
    video.removeEventListener('loadedmetadata', handler.toJS);
    if (!completer.isCompleted) completer.complete();
  }

  video.addEventListener('loadedmetadata', handler.toJS);
  await completer.future.timeout(const Duration(seconds: 20));
}

Future<void> _seekVideo(web.HTMLVideoElement video, double seconds) async {
  if ((video.currentTime - seconds).abs() < 0.04) return;

  final completer = Completer<void>();
  void handler(web.Event _) {
    video.removeEventListener('seeked', handler.toJS);
    if (!completer.isCompleted) completer.complete();
  }

  video.addEventListener('seeked', handler.toJS);
  video.currentTime = seconds;
  await completer.future.timeout(const Duration(seconds: 8));
}

Uint8List _jpegBytesFromDataUrl(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  if (comma < 0) return Uint8List(0);
  try {
    return Uint8List.fromList(base64Decode(dataUrl.substring(comma + 1)));
  } catch (_) {
    return Uint8List(0);
  }
}

String? _mimeFromFileName(String? fileName) {
  final lower = fileName?.toLowerCase() ?? '';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  return null;
}
