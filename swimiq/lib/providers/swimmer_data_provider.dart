import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/services/gemini_swim_analysis_service.dart';
import '../core/utils/supabase_table_errors.dart';
import '../core/utils/youth_friendly_analysis.dart';
import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/services/video_analysis_presenter.dart';
import '../core/services/video_analysis_scores.dart';
import '../core/utils/passport_metrics.dart';
import '../core/utils/swim_analytics.dart';
import '../data/models/meet_result.dart';
import '../data/models/personal_best_entry.dart';
import '../data/models/race_log.dart';
import '../data/models/swim_goal.dart';
import '../data/models/swim_pose_metrics.dart';
import '../data/models/swim_schedule_entry.dart';
import '../data/models/swimmer_profile.dart';
import '../data/models/video_models.dart';
import '../data/models/usa_time_standard.dart';
import 'app_providers.dart';

class SwimmerData {
  const SwimmerData({
    required this.raceLogs,
    required this.goals,
    required this.meetResults,
    this.profile,
    this.videos = const [],
    this.videoAnalyses = const [],
    this.usaStandards = const [],
    this.schedules = const [],
    required this.motivationalStandards,
  });

  final List<RaceLog> raceLogs;
  final List<SwimGoal> goals;
  final List<MeetResult> meetResults;
  final SwimmerProfile? profile;
  final List<SwimVideo> videos;
  final List<SwimVideoAnalysis> videoAnalyses;
  final List<UsaTimeStandard> usaStandards;
  final List<SwimScheduleEntry> schedules;
  final UsaMotivationalStandardsCatalog motivationalStandards;

  SwimVideoAnalysis? analysisForVideo(String? videoId) {
    if (videoId == null || videoId.isEmpty) return null;
    final matches = videoAnalyses
        .where(
          (analysis) =>
              analysis.swimVideoId == videoId && !analysis.isLegacyRulesEngine,
        )
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    final latest = matches.first;
    if (VideoAnalysisScores.isPlaceholderAnalysis(latest)) {
      return null;
    }
    return latest;
  }

  List<SwimVideo> get userFacingVideos =>
      videos.where((video) => video.isUserFacing).toList();

  List<SwimVideoAnalysis> get userFacingVideoAnalyses {
    final videoIds =
        userFacingVideos.map((video) => video.id).whereType<String>().toSet();
    return videoAnalyses
        .where(
          (analysis) =>
              !analysis.isLegacyRulesEngine &&
              analysis.swimVideoId != null &&
              videoIds.contains(analysis.swimVideoId),
        )
        .toList();
  }

  List<PersonalBestEntry> get personalBests =>
      SwimAnalytics.personalBestsFromMeets(meetResults: meetResults);

  int get swimIqScore => SwimAnalytics.calculateSwimIqScore(
        raceLogs: raceLogs,
        goals: goals,
        meetResults: meetResults,
        videos: userFacingVideos,
        analyses: userFacingVideoAnalyses,
      );

  String displayName(String swimmerName) {
    final preferred = profile?.preferredName?.trim();
    if (preferred != null && preferred.isNotEmpty) return preferred;
    final fullName = profile?.displayName.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return swimmerName;
  }

  PassportSnapshot passportSnapshot(String swimmerName) => PassportMetrics.build(
        swimmerName: swimmerName,
        profile: profile,
        raceLogs: raceLogs,
        goals: goals,
        meetResults: meetResults,
        videos: userFacingVideos,
        videoAnalyses: userFacingVideoAnalyses,
        motivationalStandards: motivationalStandards,
        schedules: schedules,
      );

  SwimmerData copyWith({
    List<RaceLog>? raceLogs,
    List<SwimGoal>? goals,
    List<MeetResult>? meetResults,
    SwimmerProfile? profile,
    List<SwimVideo>? videos,
    List<SwimVideoAnalysis>? videoAnalyses,
    List<UsaTimeStandard>? usaStandards,
    List<SwimScheduleEntry>? schedules,
    UsaMotivationalStandardsCatalog? motivationalStandards,
  }) {
    return SwimmerData(
      raceLogs: raceLogs ?? this.raceLogs,
      goals: goals ?? this.goals,
      meetResults: meetResults ?? this.meetResults,
      profile: profile ?? this.profile,
      videos: videos ?? this.videos,
      videoAnalyses: videoAnalyses ?? this.videoAnalyses,
      usaStandards: usaStandards ?? this.usaStandards,
      schedules: schedules ?? this.schedules,
      motivationalStandards:
          motivationalStandards ?? this.motivationalStandards,
    );
  }
}

class SwimmerDataNotifier extends AsyncNotifier<SwimmerData?> {
  final Map<String, SwimVideoAnalysis> _localAnalysesByVideoId = {};

  @override
  Future<SwimmerData?> build() async {
    final swimmer = ref.watch(activeSwimmerProvider);
    if (swimmer == null || swimmer.isEmpty) return null;
    return _load(swimmer);
  }

  List<SwimVideoAnalysis> _mergeAnalyses(List<SwimVideoAnalysis> remote) {
    final merged = <String, SwimVideoAnalysis>{
      for (final analysis in remote)
        if (analysis.swimVideoId != null && analysis.swimVideoId!.isNotEmpty)
          analysis.swimVideoId!: analysis,
    };
    merged.addAll(_localAnalysesByVideoId);
    return merged.values.toList();
  }

  Future<SwimmerData> _load(String swimmer) async {
    final repository = ref.read(swimIqRepositoryProvider);

    final raceLogs = await repository.fetchRaceLogs(swimmer);
    final goals = await repository.fetchGoals(swimmer);
    final meetResults = await repository.fetchMeetResults(swimmer);
    final profile = await repository.fetchProfile(swimmer);

    List<SwimVideo> videos = [];
    List<SwimVideoAnalysis> videoAnalyses = [];
    List<SwimScheduleEntry> schedules = [];

    try {
      schedules = await repository.fetchSchedules(swimmer);
    } catch (_) {}

    try {
      videos = (await repository.fetchSwimVideos(swimmer))
          .where((video) => video.isUserFacing)
          .toList();
    } catch (_) {}

    try {
      final remoteAnalyses = await repository.fetchVideoAnalyses(swimmer);
      videoAnalyses = _mergeAnalyses(remoteAnalyses)
          .where(
            (analysis) =>
                !analysis.isLegacyRulesEngine &&
                analysis.swimVideoId != null &&
                videos.any((video) => video.id == analysis.swimVideoId),
          )
          .toList();
    } catch (_) {}

    final motivationalStandards =
        await ref.read(usaMotivationalStandardsCatalogProvider.future);
    final usaStandards = motivationalStandards.flatStandards;

    return SwimmerData(
      raceLogs: raceLogs,
      goals: goals,
      meetResults: meetResults,
      profile: profile,
      videos: videos,
      videoAnalyses: _mergeAnalyses(videoAnalyses),
      usaStandards: usaStandards,
      schedules: schedules,
      motivationalStandards: motivationalStandards,
    );
  }

  Future<void> _reloadPreservingUi() async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null || swimmer.isEmpty) return;
    try {
      final data = await _load(swimmer);
      state = AsyncData(data);
    } catch (_) {
      // Optimistic local state remains visible.
    }
  }

  SwimVideoAnalysis _fallbackVideoAnalysis({
    required SwimVideo video,
    required SwimmerData current,
    SwimPoseMetrics? poseMetrics,
    String? geminiFallbackReason,
    String? geminiErrorRaw,
  }) {
    final analysis = ref.read(aiSwimAnalysisServiceProvider).analyze(
          video: video,
          raceLogs: current.raceLogs,
          goals: current.goals,
          profile: current.profile,
          standards: current.usaStandards,
          poseMetrics: poseMetrics,
        );
    final json = Map<String, dynamic>.from(analysis.analysisJson ?? {});
    if (geminiFallbackReason != null && geminiFallbackReason.trim().isNotEmpty) {
      json['gemini_fallback_reason'] = geminiFallbackReason.trim();
    }
    if (geminiErrorRaw != null && geminiErrorRaw.trim().isNotEmpty) {
      json['gemini_error_raw'] = geminiErrorRaw.trim();
    }
    return YouthFriendlyAnalysis.sanitizeAnalysis(
      analysis.copyWith(analysisJson: json),
    );
  }

  String _friendlyGeminiFallbackMessage(String raw) {
    final extracted = _extractGeminiErrorDetail(raw);
    final lower = extracted.toLowerCase();
    if (lower.contains('too large') ||
        lower.contains('413') ||
        lower.contains('payload')) {
      final sizeMatch = RegExp(
        r'yours is\s*~?\s*(\d+)\s*MB',
        caseSensitive: false,
      ).firstMatch(extracted);
      final theirs = sizeMatch?.group(1);
      final sizeHint = theirs != null ? ' (yours is about $theirs MB)' : '';
      return 'This video file is too large for AI analysis$sizeHint. '
          'Cloud analysis accepts files up to '
          '${AppConstants.maxGeminiVideoMb} MB — typical phone race clips fit. '
          'If yours is larger, trim or re-export under '
          '${AppConstants.maxGeminiVideoMb} MB, then Analyze again. '
          'Notes-based coaching was saved for now.';
    }
    if (lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('idle_timeout') ||
        lower.contains('504')) {
      return 'Analysis took too long. Try a shorter clip (under 60 seconds) '
          'and tap Analyze again. Notes-based coaching was saved for now.';
    }
    if (lower.contains('unauthorized') || lower.contains('authorization')) {
      return 'Please sign in again, then re-run analysis. '
          'Notes-based coaching was saved for now.';
    }
    if (lower.contains('could not download video')) {
      return 'Could not load this video for analysis. Try re-uploading, '
          'then Analyze again. Notes-based coaching was saved for now.';
    }
    if (lower.contains('pgrst205') ||
        (lower.contains('swim_video_analyses') &&
            lower.contains('could not find'))) {
      return SupabaseTableErrors.missingVideoAnalysesMessage();
    }
    if (lower.contains('high demand') ||
        lower.contains('unavailable') ||
        lower.contains('503') ||
        lower.contains('is busy right now') ||
        lower.contains('resource_exhausted') ||
        lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('limit: 0')) {
      return 'AI coaching is busy right now. Wait a minute or two, '
          'then tap Analyze again.';
    }
    if (lower.contains('worker_resource_limit') ||
        lower.contains('not having enough compute resources') ||
        lower.contains('status: 546') ||
        (lower.contains('not found') && lower.contains('function')) ||
        lower.contains('gemini_api_key') ||
        lower.contains('api key') ||
        lower.contains('permission_denied') ||
        lower.contains('billing') ||
        lower.contains('gemini')) {
      return 'AI video analysis is temporarily unavailable. '
          'Notes-based coaching was saved. Try again shortly, '
          'or email support@swimiqapp.com if it keeps failing.';
    }
    return 'AI video analysis was unavailable — notes-based coaching was saved. '
        'Try Analyze again in a few minutes.';
  }

  /// Pulls the nested `error:` text from Supabase FunctionException strings.
  String _extractGeminiErrorDetail(String raw) {
    final match = RegExp(
      r'error:\s*([^},]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    return match?.group(1)?.trim() ?? raw;
  }

  Future<void> _persistVideoAnalysis({
    required String videoId,
    required SwimVideo video,
    required SwimVideoAnalysis analysis,
    bool skipIfAlreadySaved = false,
  }) async {
    if (skipIfAlreadySaved) {
      _localAnalysesByVideoId[videoId] = analysis;
      final refreshed = state.value;
      if (refreshed != null) {
        state = AsyncData(
          refreshed.copyWith(
            videoAnalyses: _mergeAnalyses(refreshed.videoAnalyses),
          ),
        );
      }
      return;
    }

    final analysisWithIds = analysis.copyWith(
      swimVideoId: videoId,
      swimmer: video.swimmer,
    );

    try {
      final saved = await ref
          .read(swimIqRepositoryProvider)
          .insertVideoAnalysis(analysisWithIds);
      _localAnalysesByVideoId[videoId] = saved;
    } catch (_) {
      _localAnalysesByVideoId[videoId] = analysisWithIds.copyWith(
        id: 'local-$videoId',
      );
    }

    final refreshed = state.value;
    if (refreshed != null) {
      state = AsyncData(
        refreshed.copyWith(
          videoAnalyses: _mergeAnalyses(refreshed.videoAnalyses),
        ),
      );
    }
  }

  Future<void> refresh() async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null || swimmer.isEmpty) {
      state = const AsyncData(null);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(swimmer));
  }

  Future<String?> addRaceLog(RaceLog log) async {
    try {
      await ref.read(swimIqRepositoryProvider).insertRaceLog(log);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateRaceLog(RaceLog log) async {
    try {
      await ref.read(swimIqRepositoryProvider).updateRaceLog(log);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> deleteRaceLog(int id) async {
    try {
      await ref.read(swimIqRepositoryProvider).deleteRaceLog(id);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> addGoal(SwimGoal goal) async {
    try {
      await ref.read(swimIqRepositoryProvider).insertGoal(goal);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateGoal(SwimGoal goal) async {
    try {
      await ref.read(swimIqRepositoryProvider).updateGoal(goal);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> deleteGoal(int id) async {
    try {
      await ref.read(swimIqRepositoryProvider).deleteGoal(id);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> addMeetResult(MeetResult result) async {
    try {
      await ref.read(swimIqRepositoryProvider).insertMeetResult(result);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateMeetResult(MeetResult result) async {
    try {
      await ref.read(swimIqRepositoryProvider).updateMeetResult(result);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> deleteMeetResult(int id) async {
    try {
      await ref.read(swimIqRepositoryProvider).deleteMeetResult(id);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> addSchedule(SwimScheduleEntry entry) async {
    try {
      await ref.read(swimIqRepositoryProvider).insertSchedule(entry);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateSchedule(SwimScheduleEntry entry) async {
    try {
      await ref.read(swimIqRepositoryProvider).updateSchedule(entry);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> deleteSchedule(int id) async {
    try {
      await ref.read(swimIqRepositoryProvider).deleteSchedule(id);
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> ensureSwimmerProfileLinked({
    required String swimmerName,
    String? preferredName,
    String? email,
  }) async {
    try {
      await ref.read(swimIqRepositoryProvider).ensureSwimmerProfile(
            swimmerName: swimmerName,
            preferredName: preferredName,
            email: email,
          );
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> saveProfile(SwimmerProfile profile) async {
    try {
      final saved =
          await ref.read(swimIqRepositoryProvider).saveProfile(profile);
      final current = state.value;
      if (current != null) {
        state = AsyncData(current.copyWith(profile: saved));
      }
      await refresh();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> uploadVideo({
    required String fileName,
    required List<int> bytes,
    String? title,
    String? stroke,
    String? distance,
    String? course,
    String? notes,
  }) async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return 'No swimmer selected.';
    if (bytes.length > AppConstants.maxGeminiVideoBytes) {
      final mb = (bytes.length / (1024 * 1024)).ceil();
      return 'This video file is about $mb MB. AI analysis accepts up to '
          '${AppConstants.maxGeminiVideoMb} MB (typical phone race clips fit). '
          'Trim or re-export under ${AppConstants.maxGeminiVideoMb} MB, '
          'then upload again.';
    }

    try {
      final inserted = await ref.read(videoStorageServiceProvider).uploadSwimVideo(
            swimmer: swimmer,
            fileName: fileName,
            bytes: Uint8List.fromList(bytes),
            title: title,
            stroke: stroke,
            distance: distance,
            course: course,
            notes: notes,
          );

      final current = state.value;
      if (current != null && inserted.id != null && inserted.isUserFacing) {
        final updatedVideos = [
          inserted,
          ...current.videos
              .where((video) => video.id != inserted.id && video.isUserFacing),
        ];
        state = AsyncData(
          current.copyWith(
            videos: updatedVideos,
            videoAnalyses: _mergeAnalyses(current.videoAnalyses),
          ),
        );
      }

      try {
        await refresh();
      } catch (_) {
        // Upload succeeded; optimistic state already contains the new video.
      }
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> checkVideoServerHealth() async {
    try {
      final health =
          await ref.read(geminiSwimAnalysisServiceProvider).checkServerHealth();
      return health.message;
    } on GeminiAnalysisException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  /// Clears saved placeholder analyses (old failed tries) from DB + local state.
  Future<void> clearPlaceholderVideoAnalyses() async {
    final current = state.value;
    if (current == null) return;

    final placeholders = current.videoAnalyses
        .where(VideoAnalysisScores.isPlaceholderAnalysis)
        .toList();
    if (placeholders.isEmpty) return;

    final videoIds = placeholders
        .map((a) => a.swimVideoId)
        .whereType<String>()
        .toSet();

    for (final videoId in videoIds) {
      try {
        await ref
            .read(swimIqRepositoryProvider)
            .deletePlaceholderAnalysesForVideo(videoId);
        _localAnalysesByVideoId.remove(videoId);
      } catch (_) {
        // Best effort — UI still hides placeholders via analysisForVideo.
      }
    }

    state = AsyncData(
      current.copyWith(
        videoAnalyses: current.videoAnalyses
            .where((a) => !VideoAnalysisScores.isPlaceholderAnalysis(a))
            .toList(),
      ),
    );
  }

  Future<String?> deleteVideo(SwimVideo video) async {
    final videoId = video.id;
    if (videoId == null || videoId.isEmpty) {
      return 'This video cannot be deleted (missing id).';
    }

    try {
      await ref.read(videoStorageServiceProvider).deleteSwimVideo(
            videoId: videoId,
            storagePath: video.storagePath,
          );

      final current = state.value;
      if (current != null) {
        _localAnalysesByVideoId.remove(videoId);
        state = AsyncData(
          current.copyWith(
            videos: current.videos
                .where((entry) => entry.id != videoId)
                .toList(),
            videoAnalyses: current.videoAnalyses
                .where((analysis) => analysis.swimVideoId != videoId)
                .toList(),
          ),
        );
      }

      await _reloadPreservingUi();

      final stillThere =
          state.value?.videos.any((entry) => entry.id == videoId) ?? false;
      if (stillThere) {
        return 'Video could not be deleted. Sign in again and retry.';
      }

      return null;
    } catch (error) {
      if (SupabaseTableErrors.isMissingTable(
        error,
        tableName: 'swim_video_analyses',
      )) {
        return SupabaseTableErrors.missingVideoAnalysesMessage();
      }
      return error.toString();
    }
  }

  Future<SwimVideoAnalysis?> _pollVideoAnalysisResult(String videoId) async {
    try {
      await _reloadPreservingUi();
    } catch (_) {
      // Continue polling with current in-memory state.
    }

    final current = state.value;
    if (current == null) return null;

    final gemini = current.analysisForVideo(videoId);
    if (gemini != null) return gemini;

    final matches = current.videoAnalyses
        .where((analysis) => analysis.swimVideoId == videoId)
        .toList();
    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final latest = matches.first;
    if (latest.isGeminiEngine) return latest;

    final reason = latest.analysisJson?['gemini_fallback_reason']?.toString();
    if (reason != null && reason.trim().isNotEmpty) {
      return latest;
    }
    return null;
  }

  static const _poseAnalysisTimeout = Duration(seconds: 8);
  static const _videoDownloadTimeout = Duration(seconds: 12);

  Future<SwimPoseMetrics?> _tryOptionalPoseMetrics(SwimVideo video) async {
    if (kIsWeb) return null;

    final poseService = ref.read(swimPoseAnalysisServiceProvider);
    if (!poseService.isSupported) return null;

    try {
      return await Future<SwimPoseMetrics?>(() async {
        final bytes = await ref
            .read(videoStorageServiceProvider)
            .downloadVideoBytes(video.storagePath)
            .timeout(_videoDownloadTimeout);
        return poseService.analyzeVideoBytes(
          bytes,
          fileName: video.storagePath,
        );
      }).timeout(_poseAnalysisTimeout);
    } catch (_) {
      // Pose metrics are optional; Gemini analysis proceeds without them.
      return null;
    }
  }

  Future<String?> analyzeVideo(SwimVideo video) async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return 'No swimmer selected.';

    final videoId = video.id;
    if (videoId == null || videoId.isEmpty) {
      return 'Video must have a UUID before running analysis.';
    }

    final current = state.value;
    if (current == null) return 'No swimmer data loaded.';

    try {
      // Clear old failed attempts so stale gemini-1.5 errors do not show during this run.
      try {
        await ref
            .read(swimIqRepositoryProvider)
            .deletePlaceholderAnalysesForVideo(videoId);
        _localAnalysesByVideoId.remove(videoId);
      } catch (_) {}

      // Pose is optional enrichment — never block Gemini (MediaPipe CDN can hang on web).
      final poseMetrics = await _tryOptionalPoseMetrics(video);

      SwimVideoAnalysis analysis;
      String? fallbackNotice;

      try {
        analysis = await ref.read(geminiSwimAnalysisServiceProvider).analyzeVideo(
              video: video,
              raceLogs: current.raceLogs,
              goals: current.goals,
              profile: current.profile,
              poseMetrics: poseMetrics,
              pollForResult: () => _pollVideoAnalysisResult(videoId),
            );
      } on GeminiAnalysisException catch (error) {
        final friendly = _friendlyGeminiFallbackMessage(error.message);
        analysis = _fallbackVideoAnalysis(
          video: video,
          current: current,
          poseMetrics: poseMetrics,
          geminiFallbackReason: friendly,
          geminiErrorRaw: error.message,
        );
        // Keep raw detail in analysis JSON for support; never show it in the SnackBar.
        fallbackNotice = friendly;
      } catch (error) {
        final raw = error.toString();
        final friendly = _friendlyGeminiFallbackMessage(raw);
        analysis = _fallbackVideoAnalysis(
          video: video,
          current: current,
          poseMetrics: poseMetrics,
          geminiFallbackReason: friendly,
          geminiErrorRaw: raw,
        );
        fallbackNotice = friendly;
      }

      await _persistVideoAnalysis(
        videoId: videoId,
        video: video,
        analysis: analysis,
        skipIfAlreadySaved: analysis.id != null && !analysis.id!.startsWith('local-'),
      );

      await _reloadPreservingUi();

      // Only count successful analyses against coach Elite sneak-peek limits.
      if (fallbackNotice == null) {
        await ref
            .read(subscriptionStateProvider.notifier)
            .recordCoachAiAnalysis();
      }
      return fallbackNotice;
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> updateAnalysisCoachNotes({
    required String videoId,
    required String notes,
  }) async {
    final current = state.value;
    if (current == null) return;

    final existing = current.analysisForVideo(videoId);
    if (existing == null) return;

    final updated = VideoAnalysisPresenter.withCoachNotes(existing, notes);
    _localAnalysesByVideoId[videoId] = updated;
    state = AsyncData(
      current.copyWith(
        videoAnalyses: _mergeAnalyses(current.videoAnalyses),
      ),
    );
  }

  Future<String?> uploadProfilePhoto({
    required String fileName,
    required List<int> bytes,
  }) async {
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return 'No swimmer selected.';

    final current = state.value;
    final profile = current?.profile;
    if (profile == null) {
      return 'Save the athlete passport profile before uploading a photo.';
    }

    try {
      final photoUrl = await ref.read(profilePhotoServiceProvider).uploadProfilePhoto(
            swimmer: swimmer,
            fileName: fileName,
            bytes: Uint8List.fromList(bytes),
          );

      final updated = profile.copyWith(
        athleteNotes: SwimmerProfile.composeAthleteNotes(
          gender: profile.gender,
          height: profile.height,
          weight: profile.weight,
          dominantHand: profile.dominantHand,
          trainingGroup: profile.trainingGroup,
          profilePhotoUrl: photoUrl,
          gpa: profile.gpa,
          athleteWebsite: profile.athleteWebsite,
          otherInterests: profile.otherInterests,
          notes: profile.notesBody,
        ),
      );

      return saveProfile(updated);
    } catch (error) {
      return error.toString();
    }
  }

}

final swimmerDataProvider =
    AsyncNotifierProvider<SwimmerDataNotifier, SwimmerData?>(
  SwimmerDataNotifier.new,
);
