import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/video_models.dart';
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
    final extension = ext.isEmpty ? '.mp4' : ext;
    final userId = _client.auth.currentUser?.id;
    // Prefer `{userId}/{uuid}{ext}` for private storage RLS when authenticated.
    final storagePath = userId != null && userId.isNotEmpty
        ? '$userId/${_uuid.v4()}$extension'
        : '$swimmer/${_uuid.v4()}$extension';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // Legacy public URL helper (V2 playback should prefer signed URLs from API).
    final publicUrl = _client.storage
        .from(bucketName)
        .getPublicUrl(storagePath);

    final video = SwimVideo(
      swimmer: swimmer,
      title: title ?? fileName,
      stroke: stroke,
      distance: distance,
      course: course,
      storagePath: storagePath,
      videoUrl: publicUrl,
      notes: notes,
      userId: userId,
    );

    return _repository.insertSwimVideo(video);
  }

  /// Overwrite an existing storage object (used after auto-shrink for 413 retries).
  Future<SwimVideo> replaceSwimVideoBytes({
    required SwimVideo video,
    required Uint8List bytes,
    String contentType = 'video/webm',
    String? fileNameHint,
  }) async {
    final oldPath = video.storagePath.trim();
    if (oldPath.isEmpty) {
      throw StateError('Video has no storage path to replace.');
    }

    final userId = _client.auth.currentUser?.id;
    final ext = contentType.contains('webm')
        ? '.webm'
        : (p.extension(fileNameHint ?? oldPath).isEmpty
            ? '.mp4'
            : p.extension(fileNameHint ?? oldPath));
    final storagePath = userId != null && userId.isNotEmpty
        ? '$userId/${_uuid.v4()}$ext'
        : '${video.swimmer}/${_uuid.v4()}$ext';

    await _client.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    final publicUrl =
        _client.storage.from(bucketName).getPublicUrl(storagePath);

    // Best-effort cleanup of the oversized original.
    if (oldPath != storagePath) {
      try {
        await _client.storage.from(bucketName).remove([oldPath]);
      } catch (_) {}
    }

    final updated = video.copyWith(
      storagePath: storagePath,
      videoUrl: publicUrl,
    );
    if (video.id != null && video.id!.isNotEmpty) {
      return _repository.updateSwimVideo(updated);
    }
    return updated;
  }

  Future<Uint8List> downloadVideoBytes(String storagePath) async {
    return _client.storage.from(bucketName).download(storagePath);
  }

  /// Playback URL for private `swim-videos` objects.
  /// Prefers a short-lived signed URL; falls back to stored `videoUrl`.
  Future<String?> resolvePlaybackUrl(
    SwimVideo video, {
    int expiresIn = 3600,
  }) async {
    final path = video.storagePath.trim();
    if (path.isNotEmpty) {
      try {
        return await _client.storage
            .from(bucketName)
            .createSignedUrl(path, expiresIn);
      } catch (_) {
        // Fall through to legacy/public URL when signing is unavailable.
      }
    }
    final url = video.videoUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  Future<void> deleteSwimVideo({
    required String videoId,
    required String storagePath,
  }) async {
    try {
      await _client.storage.from(bucketName).remove([storagePath]);
    } catch (_) {
      // Metadata delete still proceeds if the file was already removed.
    }
    await _repository.deleteSwimVideo(videoId);
  }
}
