import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/swim_video.dart';
import '../../data/repositories/swimiq_repository.dart';

class VideoStorageService {
  VideoStorageService(this._client, this._repository);

  static const bucketName = 'swim-videos';

  final SupabaseClient _client;
  final SwimIqRepository _repository;
  final _uuid = const Uuid();

  Future<SwimVideo> uploadSwimVideo({
    required String swimmer,
    required String fileName,
    required Uint8List bytes,
    String? title,
    String? stroke,
    String? distance,
    String? course,
    String? notes,
  }) async {
    final ext = p.extension(fileName);
    final storagePath =
        '$swimmer/${_uuid.v4()}${ext.isEmpty ? '.mp4' : ext}';

    await _client.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage.from(bucketName).getPublicUrl(storagePath);

    final video = SwimVideo(
      swimmer: swimmer,
      title: title ?? fileName,
      stroke: stroke,
      distance: distance,
      course: course,
      storagePath: storagePath,
      videoUrl: publicUrl,
      notes: notes,
    );

    return _repository.insertSwimVideo(video);
  }
}
