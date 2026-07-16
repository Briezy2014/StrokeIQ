import 'dart:js_interop';
import 'dart:typed_data';

import '../../data/models/swim_pose_metrics.dart';
import '../utils/swim_pose_metrics_calculator.dart';

/// Chrome/web MediaPipe pose via JS bridge (no native Flutter plugins).
/// Capped so Gemini analysis is never blocked by CDN/model load.
const _poseBridgeTimeout = Duration(seconds: 12);

bool get isPoseAnalysisSupported => true;

@JS('swimiqPoseFromVideoBytes')
external JSPromise<JSAny?> _swimiqPoseFromVideoBytes(JSUint8Array bytes);

Future<SwimPoseMetrics?> analyzeVideoBytesImpl(
  Uint8List bytes, {
  String? fileName,
}) async {
  if (!_isBridgeReady()) {
    return const SwimPoseMetrics(
      engine: SwimPoseMetrics.engineId,
      framesSampled: 0,
      framesWithPose: 0,
      observations: [
        'MediaPipe bridge not loaded — hard refresh Chrome (Ctrl+F5), then Analyze again.',
      ],
    );
  }

  try {
    final raw = await _swimiqPoseFromVideoBytes(bytes.toJS)
        .toDart
        .timeout(
          _poseBridgeTimeout,
          onTimeout: () => throw StateError('MediaPipe timed out'),
        );
    if (raw is! JSObject) return null;

    final map = raw.dartify();
    if (map is! Map) return null;

    if (map['ok'] != true) {
      final err = map['error']?.toString();
      return SwimPoseMetrics(
        engine: SwimPoseMetrics.engineId,
        framesSampled: 0,
        framesWithPose: 0,
        observations: [
          if (err != null && err.isNotEmpty)
            'MediaPipe: $err'
          else
            'MediaPipe could not analyze this clip — try a clearer side-on angle.',
        ],
      );
    }

    final framesSampled = _asInt(map['framesSampled']);
    final snapshots = _parseSnapshots(map['snapshots']);

    if (snapshots.isEmpty) {
      return SwimPoseMetrics(
        engine: SwimPoseMetrics.engineId,
        framesSampled: framesSampled,
        framesWithPose: 0,
        observations: const [
          'MediaPipe could not detect a swimmer body — film side-on with the full body in frame.',
        ],
      );
    }

    final metrics = SwimPoseMetricsCalculator.compute(snapshots);
    return SwimPoseMetrics(
      engine: metrics.engine,
      framesSampled: framesSampled,
      framesWithPose: snapshots.length,
      avgBodyLineAngleDeg: metrics.avgBodyLineAngleDeg,
      hipDropDegrees: metrics.hipDropDegrees,
      headLiftScore: metrics.headLiftScore,
      avgElbowAngleDeg: metrics.avgElbowAngleDeg,
      estimatedStrokeCycles: metrics.estimatedStrokeCycles,
      kickSymmetryScore: metrics.kickSymmetryScore,
      bodyMechanicsPro: metrics.bodyMechanicsPro,
      bodyMechanicsCon: metrics.bodyMechanicsCon,
      bodyMechanicsSuggestions: metrics.bodyMechanicsSuggestions,
      observations: metrics.observations,
    );
  } catch (error) {
    return SwimPoseMetrics(
      engine: SwimPoseMetrics.engineId,
      framesSampled: 0,
      framesWithPose: 0,
      observations: [
        'MediaPipe error: $error',
      ],
    );
  }
}

bool _isBridgeReady() {
  final global = globalContext.dartify();
  if (global is Map) {
    return global.containsKey('swimiqPoseFromVideoBytes');
  }
  return false;
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<PoseFrameSnapshot> _parseSnapshots(Object? raw) {
  if (raw is! List) return const [];

  final snapshots = <PoseFrameSnapshot>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final landmarksRaw = entry['landmarks'];
    if (landmarksRaw is! Map) continue;

    final landmarks = <String, PosePoint>{};
    landmarksRaw.forEach((key, value) {
      if (value is! Map) return;
      final x = _asDouble(value['x']);
      final y = _asDouble(value['y']);
      final visibility = _asDouble(value['visibility']) ?? 1;
      if (x == null || y == null) return;
      landmarks[key.toString()] = PosePoint(
        x: x,
        y: y,
        visibility: visibility,
      );
    });

    if (landmarks.length < 6) continue;
    snapshots.add(
      PoseFrameSnapshot(
        timestampSec: _asDouble(entry['timestampSec']) ?? snapshots.length.toDouble(),
        landmarks: landmarks,
      ),
    );
  }
  return snapshots;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
