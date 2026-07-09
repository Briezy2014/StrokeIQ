import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/ai_swim_analysis_service.dart';
import '../core/services/gemini_swim_analysis_service.dart';
import '../core/utils/youth_friendly_analysis.dart';
import '../core/services/usa_motivational_standards_catalog.dart';
import '../core/services/video_analysis_presenter.dart';
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
    return matches.first;
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

  int get swimIqScore =>
      SwimAnalytics.calculateSwimIqScore(raceLogs: raceLogs, goals: goals);

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
    return YouthFriendlyAnalysis.sanitizeAnalysis(
      analysis.copyWith(analysisJson: json),
    );
  }

  String _friendlyGeminiFallbackMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('gemini_api_key')) {
      return 'Gemini is not configured yet — add GEMINI_API_KEY in Supabase '
          '(see swimiq/docs/GEMINI_SETUP.md). Notes-based coaching saved for now.';
    }
    if (lower.contains('too large')) {
      return 'Video is too large for Gemini (max ~18 MB). Trim the clip and re-run. '
          'Notes-based coaching saved for now.';
    }
    if (lower.contains('unauthorized') || lower.contains('authorization')) {
      return 'Sign in again, then re-run analysis. Notes-based coaching saved for now.';
    }
    if (lower.contains('could not download video')) {
      return 'Could not load the video from storage for Gemini. Notes-based coaching saved for now.';
    }
    return 'Gemini video analysis was unavailable — notes-based coaching saved. '
        'Check swimiq/docs/GEMINI_SETUP.md if this keeps happening.';
  }

  Future<void> _persistVideoAnalysis({
    required String videoId,
    required SwimVideo video,
    required SwimVideoAnalysis analysis,
  }) async {
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
      SwimPoseMetrics? poseMetrics;
      final poseService = ref.read(swimPoseAnalysisServiceProvider);
      if (poseService.isSupported) {
        try {
          final bytes = await ref
              .read(videoStorageServiceProvider)
              .downloadVideoBytes(video.storagePath);
          poseMetrics = await poseService.analyzeVideoBytes(
            bytes,
            fileName: video.storagePath,
          );
        } catch (_) {
          // Pose metrics are optional; Gemini analysis can still run.
        }
      }

      SwimVideoAnalysis analysis;
      String? fallbackNotice;

      try {
        analysis = await ref.read(geminiSwimAnalysisServiceProvider).analyzeVideo(
              video: video,
              raceLogs: current.raceLogs,
              goals: current.goals,
              profile: current.profile,
              poseMetrics: poseMetrics,
            );
      } on GeminiAnalysisException catch (error) {
        analysis = _fallbackVideoAnalysis(
          video: video,
          current: current,
          poseMetrics: poseMetrics,
          geminiFallbackReason: error.message,
        );
        fallbackNotice = _friendlyGeminiFallbackMessage(error.message);
      } catch (error) {
        analysis = _fallbackVideoAnalysis(
          video: video,
          current: current,
          poseMetrics: poseMetrics,
          geminiFallbackReason: error.toString(),
        );
        fallbackNotice = _friendlyGeminiFallbackMessage(error.toString());
      }

      await _persistVideoAnalysis(
        videoId: videoId,
        video: video,
        analysis: analysis,
      );

      await _reloadPreservingUi();

      await ref.read(subscriptionStateProvider.notifier).recordCoachAiAnalysis();
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
