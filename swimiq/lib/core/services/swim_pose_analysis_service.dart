import 'dart:typed_data';

import '../../data/models/swim_pose_metrics.dart';
import 'swim_pose_analysis_impl_stub.dart'
    if (dart.library.io) 'swim_pose_analysis_impl_io.dart'
    if (dart.library.html) 'swim_pose_analysis_impl_web.dart';

/// On-device pose metrics (MediaPipe-compatible BlazePose).
///
/// Optional — Gemini coaching works without pose. Pose returns on Android later.
class SwimPoseAnalysisService {
  bool get isSupported => isPoseAnalysisSupported;

  Future<SwimPoseMetrics?> analyzeVideoBytes(
    Uint8List bytes, {
    String? fileName,
  }) {
    return analyzeVideoBytesImpl(bytes, fileName: fileName);
  }
}
