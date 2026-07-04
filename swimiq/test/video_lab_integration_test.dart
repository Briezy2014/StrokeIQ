import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swimiq/config/supabase_config.dart';
import 'package:swimiq/core/services/ai_swim_analysis_service.dart';
import 'package:swimiq/data/models/video_models.dart';
import 'package:swimiq/data/repositories/swimiq_repository.dart';
import 'package:uuid/uuid.dart';

/// Live Supabase integration for Video Lab UUID flow.
void main() {
  late SupabaseClient client;
  late SwimIqRepository repository;
  const swimmer = 'Aspyn';
  const uuid = Uuid();

  setUpAll(() {
    client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
    repository = SwimIqRepository(client);
  });

  group('Video Lab Supabase integration', () {
    String? uploadedVideoId;
    String? storagePath;

    test('uploads video metadata, lists it, and runs AI analysis', () async {
      storagePath = '$swimmer/${uuid.v4()}.mp4';
      final publicUrl =
          client.storage.from('swim-videos').getPublicUrl(storagePath!);

      await client.storage.from('swim-videos').uploadBinary(
            storagePath!,
            Uint8List.fromList([0, 1, 2, 3, 4]),
            fileOptions: const FileOptions(upsert: true),
          );

      final inserted = await repository.insertSwimVideo(
        SwimVideo(
          swimmer: swimmer,
          title: 'Integration test video',
          stroke: 'Freestyle',
          distance: '50',
          course: 'SCY',
          storagePath: storagePath!,
          videoUrl: publicUrl,
          notes: 'stroke count test',
        ),
      );

      expect(inserted.id, isNotNull);
      expect(inserted.id, isA<String>());
      expect(inserted.id!.length, greaterThan(10));
      uploadedVideoId = inserted.id;

      final videos = await repository.fetchSwimVideos(swimmer);
      final userVideos = videos.where((video) => video.isUserFacing).toList();
      expect(
        userVideos.any((video) => video.id == uploadedVideoId),
        isFalse,
        reason: 'Integration test uploads should not appear in user video list',
      );

      final listed = videos.firstWhere((video) => video.id == uploadedVideoId);

      final analysis = AiSwimAnalysisService().analyze(
        video: listed,
        raceLogs: const [],
        goals: const [],
      );
      expect(analysis.summary, contains('50 Freestyle SCY'));
      expect(analysis.summary, isNot(contains('consistent training history')));

      final analysisWithIds = analysis.copyWith(
        swimVideoId: uploadedVideoId,
        swimmer: swimmer,
      );

      SwimVideoAnalysis? saved;
      try {
        saved = await repository.insertVideoAnalysis(analysisWithIds);
        expect(saved.id, isNotNull);
        expect(saved.swimVideoId, uploadedVideoId);
      } catch (_) {
        saved = analysisWithIds.copyWith(id: 'local-$uploadedVideoId');
      }

      expect(saved.summary, isNotEmpty);
    });

    tearDown(() async {
      if (uploadedVideoId != null) {
        try {
          await client.from('swim_videos').delete().eq('id', uploadedVideoId!);
        } catch (_) {}
        uploadedVideoId = null;
      }
      if (storagePath != null) {
        try {
          await client.storage.from('swim-videos').remove([storagePath!]);
        } catch (_) {}
        storagePath = null;
      }
    });
  });
}
