import 'dart:io';
import 'dart:typed_data';

import '../../data/models/swim_pose_metrics.dart';

/// Desktop/mobile IO builds skip on-device pose for now (web Chrome uses the
/// HTML video sampler). Avoids native OpenCV builds that break on Windows
/// paths with spaces in the username.
bool get isPoseAnalysisSupported => Platform.isAndroid || Platform.isIOS;

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  if (!isPoseAnalysisSupported) return null;

  return SwimPoseMetrics(
    engine: SwimPoseMetrics.engineId,
    framesSampled: 0,
    framesWithPose: 0,
    observations: const [
      'On-device pose sampling runs in Chrome (Flutter web). '
      'Gemini video analysis still runs from this device.',
    ],
  );
}
