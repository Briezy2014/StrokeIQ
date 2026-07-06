import 'dart:typed_data';

import '../../data/models/swim_pose_metrics.dart';

/// Pose metrics run in Flutter web (Chrome) via the HTML video sampler.
/// Desktop IO builds skip native pose to avoid Windows path-with-spaces build failures.
bool get isPoseAnalysisSupported => false;

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  return null;
}
