import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

bool get canFitVideoBytesForCloudImpl {
  try {
    return globalContext.has('swimiqFitVideoForCloud');
  } catch (_) {
    return false;
  }
}

Future<Uint8List> fitVideoBytesForCloudImpl(
  Uint8List bytes, {
  String? fileName,
  int maxBytes = 18 * 1024 * 1024,
}) async {
  if (bytes.lengthInBytes <= maxBytes) return bytes;

  if (!canFitVideoBytesForCloudImpl) {
    throw StateError(
      'Video shrink tool is not loaded. Hard refresh Chrome (Ctrl+Shift+R), '
      'then upload again.',
    );
  }

  final fn = globalContext['swimiqFitVideoForCloud'] as JSFunction;
  final promise = fn.callAsFunction(
    null,
    bytes.toJS,
    maxBytes.toJS,
  ) as JSPromise<JSUint8Array>;

  final raw = await promise.toDart.timeout(
    const Duration(seconds: 120),
    onTimeout: () => throw StateError(
      'Shrinking this video timed out. Try a shorter clip.',
    ),
  );

  final out = raw.toDart;
  if (out.isEmpty) {
    throw StateError('Could not shrink this video. Try a shorter clip.');
  }
  return out;
}
