import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef PickedImage = ({Uint8List bytes, String name});

enum _ImagePickChoice { camera, gallery, files }

/// Camera or gallery on mobile; includes file browse on web.
Future<PickedImage?> pickImageFromUserChoice(BuildContext context) async {
  final choice = await showModalBottomSheet<_ImagePickChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(context, _ImagePickChoice.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, _ImagePickChoice.gallery),
          ),
          if (kIsWeb)
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Browse files'),
              onTap: () => Navigator.pop(context, _ImagePickChoice.files),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return null;

  return switch (choice) {
    _ImagePickChoice.camera => _fromImagePicker(ImageSource.camera),
    _ImagePickChoice.gallery => _fromImagePicker(ImageSource.gallery),
    _ImagePickChoice.files => _fromFilePicker(),
  };
}

Future<PickedImage?> _fromImagePicker(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    imageQuality: 85,
    preferredCameraDevice: CameraDevice.rear,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
  return (bytes: bytes, name: name);
}

Future<PickedImage?> _fromFilePicker() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.bytes == null) return null;
  return (bytes: file.bytes!, name: file.name);
}
