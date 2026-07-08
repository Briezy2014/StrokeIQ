import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum SwimIqMediaKind { image, video }

class SwimIqPickedMedia {
  const SwimIqPickedMedia({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

/// Camera, gallery, or file picker — shared by Video Lab, Passport, schedules.
Future<SwimIqPickedMedia?> pickSwimIqMedia(
  BuildContext context, {
  required SwimIqMediaKind kind,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              kind == SwimIqMediaKind.video
                  ? Icons.videocam_outlined
                  : Icons.photo_camera_outlined,
            ),
            title: Text(kind == SwimIqMediaKind.video ? 'Record video' : 'Take photo'),
            subtitle: const Text('Use your device camera'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: Icon(
              kind == SwimIqMediaKind.video
                  ? Icons.video_library_outlined
                  : Icons.photo_library_outlined,
            ),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Choose file'),
            onTap: () => Navigator.pop(context, 'file'),
          ),
        ],
      ),
    ),
  );

  if (choice == null || !context.mounted) return null;

  final picker = ImagePicker();
  switch (choice) {
    case 'camera':
      if (kind == SwimIqMediaKind.video) {
        final video = await picker.pickVideo(source: ImageSource.camera);
        if (video == null) return null;
        final bytes = await video.readAsBytes();
        return SwimIqPickedMedia(
          fileName: video.name,
          bytes: bytes,
        );
      }
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (photo == null) return null;
      final bytes = await photo.readAsBytes();
      return SwimIqPickedMedia(
        fileName: photo.name,
        bytes: bytes,
      );
    case 'gallery':
      if (kind == SwimIqMediaKind.video) {
        final video = await picker.pickVideo(source: ImageSource.gallery);
        if (video == null) return null;
        final bytes = await video.readAsBytes();
        return SwimIqPickedMedia(
          fileName: video.name,
          bytes: bytes,
        );
      }
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (photo == null) return null;
      final bytes = await photo.readAsBytes();
      return SwimIqPickedMedia(
        fileName: photo.name,
        bytes: bytes,
      );
    case 'file':
      final result = await FilePicker.platform.pickFiles(
        type: kind == SwimIqMediaKind.video ? FileType.video : FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      if (file.bytes == null) return null;
      return SwimIqPickedMedia(
        fileName: file.name,
        bytes: file.bytes!,
      );
    default:
      return null;
  }
}
