import 'dart:typed_data';

/// Video captured from device camera or webcam.
class SwimIqCapturedVideo {
  const SwimIqCapturedVideo({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}
