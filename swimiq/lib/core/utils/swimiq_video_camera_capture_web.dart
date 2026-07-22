import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'swimiq_captured_video.dart';

/// Webcam video recording for Chrome — image_picker video camera opens files on desktop.
Future<SwimIqCapturedVideo?> captureSwimIqVideo(BuildContext context) async {
  final devices = web.window.navigator.mediaDevices;

  web.MediaStream stream;
  try {
    stream = await devices
        .getUserMedia(web.MediaStreamConstraints(
          video: true.toJS,
          audio: true.toJS,
        ))
        .toDart;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open camera/mic. Allow access in Chrome site settings.',
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
    return await showDialog<SwimIqCapturedVideo>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _WebVideoRecorderDialog(stream: stream),
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

Future<Uint8List> _blobToBytes(web.Blob blob) async {
  final arrayBuffer = await blob.arrayBuffer().toDart;
  return Uint8List.view(arrayBuffer.toDart);
}

class _WebVideoRecorderDialog extends StatefulWidget {
  const _WebVideoRecorderDialog({required this.stream});

  final web.MediaStream stream;

  @override
  State<_WebVideoRecorderDialog> createState() => _WebVideoRecorderDialogState();
}

class _WebVideoRecorderDialogState extends State<_WebVideoRecorderDialog> {
  static int _viewId = 0;
  late final String _viewType;
  late final web.HTMLVideoElement _video;
  web.MediaRecorder? _recorder;
  final List<web.Blob> _chunks = [];
  StreamSubscription<web.Event>? _metadataSub;
  JSFunction? _dataListener;
  bool _ready = false;
  bool _recording = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'swimiq-webcam-video-${_viewId++}';
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
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _metadataSub?.cancel();
    final recorder = _recorder;
    final listener = _dataListener;
    if (recorder != null && listener != null) {
      recorder.removeEventListener('dataavailable', listener);
    }
    super.dispose();
  }

  void _startRecording() {
    if (!_ready || _recording) return;
    _chunks.clear();
    final mime = web.MediaRecorder.isTypeSupported('video/webm;codecs=vp9,opus')
        ? 'video/webm;codecs=vp9,opus'
        : 'video/webm';
    _recorder = web.MediaRecorder(
      widget.stream,
      web.MediaRecorderOptions(mimeType: mime),
    );
    void onDataAvailable(web.Event event) {
      final blob = (event as web.BlobEvent).data;
      if (blob.size > 0) {
        _chunks.add(blob);
      }
    }

    _dataListener = onDataAvailable.toJS;
    _recorder!.addEventListener('dataavailable', _dataListener!);
    _recorder!.start();
    setState(() {
      _recording = true;
      _error = null;
    });
  }

  Future<void> _stopAndSave() async {
    final recorder = _recorder;
    if (recorder == null || !_recording) return;

    final completer = Completer<void>();
    void onStop(web.Event _) {
      completer.complete();
    }

    recorder.addEventListener('stop', onStop.toJS);
    recorder.stop();
    await completer.future;
    recorder.removeEventListener('stop', onStop.toJS);

    if (_chunks.isEmpty) {
      setState(() => _error = 'No video recorded. Try again.');
      return;
    }

    try {
      final blob = web.Blob(
        _chunks.map((chunk) => chunk as web.BlobPart).toList().toJS,
        web.BlobPropertyBag(type: recorder.mimeType),
      );
      final bytes = await _blobToBytes(blob);
      if (!mounted) return;
      Navigator.of(context).pop(
        SwimIqCapturedVideo(
          bytes: bytes,
          fileName: 'camera-${DateTime.now().millisecondsSinceEpoch}.webm',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _error = 'Could not save video.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record video'),
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
            if (_recording)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red.shade700, size: 14),
                    const SizedBox(width: 6),
                    const Text('Recording…', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
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
        if (!_recording)
          FilledButton.icon(
            onPressed: _ready ? _startRecording : null,
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Start'),
          )
        else
          FilledButton.icon(
            onPressed: _stopAndSave,
            icon: const Icon(Icons.stop),
            label: const Text('Stop & use'),
          ),
      ],
    );
  }
}
