import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'swimiq_captured_photo.dart';

/// Chrome/web webcam — image_picker camera opens a file dialog on desktop web.
Future<SwimIqCapturedPhoto?> captureSwimIqPhoto(BuildContext context) async {
  final devices = web.window.navigator.mediaDevices;

  web.MediaStream stream;
  try {
    stream = await devices
        .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
        .toDart;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open camera. Allow camera access for this site in Chrome.',
          ),
        ),
      );
    }
    return null;
  }

  if (!context.mounted) {
    _stopStream(stream);
    return null;
  }

  try {
    return await showDialog<SwimIqCapturedPhoto>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _WebCameraDialog(stream: stream),
    );
  } finally {
    _stopStream(stream);
  }
}

void _stopStream(web.MediaStream stream) {
  for (final track in stream.getTracks().toDart) {
    track.stop();
  }
}

class _WebCameraDialog extends StatefulWidget {
  const _WebCameraDialog({required this.stream});

  final web.MediaStream stream;

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  static int _viewId = 0;
  late final String _viewType;
  late final web.HTMLVideoElement _video;
  StreamSubscription<web.Event>? _metadataSub;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'swimiq-webcam-${_viewId++}';
    _video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..srcObject = widget.stream;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _video,
    );

    _metadataSub = _video.onLoadedMetadata.listen((_) {
      _video.play();
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _metadataSub?.cancel();
    super.dispose();
  }

  Future<void> _capture() async {
    if (!_ready || _video.videoWidth == 0 || _video.videoHeight == 0) {
      setState(() => _error = 'Camera is still starting. Try again in a second.');
      return;
    }

    try {
      final canvas = web.HTMLCanvasElement()
        ..width = _video.videoWidth
        ..height = _video.videoHeight;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) {
        setState(() => _error = 'Could not capture photo.');
        return;
      }
      ctx.drawImage(_video, 0, 0);

      final dataUrl = canvas.toDataURL('image/jpeg', 0.88.toJS);
      final comma = dataUrl.indexOf(',');
      if (comma < 0) {
        setState(() => _error = 'Could not save photo.');
        return;
      }
      final base64 = dataUrl.substring(comma + 1);
      final bytes = Uint8List.fromList(base64Decode(base64));
      if (!mounted) return;
      Navigator.of(context).pop(
        SwimIqCapturedPhoto(
          bytes: bytes,
          fileName: 'camera-${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not capture photo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Take photo'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: _ready
                    ? HtmlElementView(viewType: _viewType)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _ready ? _capture : null,
          icon: const Icon(Icons.photo_camera),
          label: const Text('Capture'),
        ),
      ],
    );
  }
}
