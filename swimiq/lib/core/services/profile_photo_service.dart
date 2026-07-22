import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProfilePhotoService {
  ProfilePhotoService(this._client);

  static const bucketName = 'swim-videos';

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto({
    required String swimmer,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ext = p.extension(fileName).toLowerCase();
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final storagePath = '$swimmer/profile-photo-${_uuid.v4()}$safeExt';

    await _client.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from(bucketName).getPublicUrl(storagePath);
  }

  Future<String> uploadSchedulePhoto({
    required String swimmer,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ext = p.extension(fileName).toLowerCase();
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final storagePath = '$swimmer/schedule-${_uuid.v4()}$safeExt';

    await _client.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from(bucketName).getPublicUrl(storagePath);
  }
}
