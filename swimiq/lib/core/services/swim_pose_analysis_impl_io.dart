import 'dart:typed_data';

import '../../data/models/swim_pose_metrics.dart';

/// Pose metrics are optional on desktop/web builds.
///
/// Gemini video coaching (Supabase Edge Function) works on all platforms.
/// On-device BlazePose/MediaPipe returns on Android builds in a future release.
bool get isPoseAnalysisSupported => false;

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  return null;
}
