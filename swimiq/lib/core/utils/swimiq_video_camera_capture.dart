import 'package:flutter/material.dart';

import 'swimiq_captured_video.dart';
import 'swimiq_video_camera_capture_mobile.dart'
    if (dart.library.js_interop) 'swimiq_video_camera_capture_web.dart' as video_impl;

/// Opens the device camera for video (webcam recorder on Chrome).
Future<SwimIqCapturedVideo?> captureSwimIqVideo(BuildContext context) =>
    video_impl.captureSwimIqVideo(context);
