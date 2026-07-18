import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/video_analytics_service.dart';
import '../core/services/video_engine_v2_service.dart';
import '../data/models/video_engine_v2/video_engine_v2_models.dart';
import 'app_providers.dart';

/// Polls job status every 2 seconds until a terminal state.
class VideoEngineV2JobNotifier extends StateNotifier<AsyncValue<AnalysisJob?>> {
  VideoEngineV2JobNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  Timer? _pollTimer;
  String? _activeJobId;
  String? _lastStage;
  bool _tickInFlight = false;
  int _consecutivePollFailures = 0;
  static const int _maxTransientFailures = 8;

  VideoEngineV2Service get _service => _ref.read(videoEngineV2ServiceProvider);
  VideoAnalyticsService get _analytics =>
      _ref.read(videoAnalyticsServiceProvider);

  Future<AnalysisJob> startPolling(String jobId) async {
    await stopPolling();
    _activeJobId = jobId;
    _consecutivePollFailures = 0;
    _tickInFlight = false;
    state = const AsyncLoading();
    try {
      final job = await _service.getStatus(jobId);
      if (_activeJobId != jobId) return job;
      _lastStage = job.stage;
      state = AsyncData(job);
      if (!job.isTerminal) {
        _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          unawaited(_tick());
        });
      } else {
        _emitTerminalAnalytics(job);
      }
      return job;
    } catch (e, st) {
      if (_activeJobId == jobId) {
        state = AsyncError(e, st);
      }
      rethrow;
    }
  }

  Future<void> _tick() async {
    final jobId = _activeJobId;
    if (jobId == null || _tickInFlight) return;
    _tickInFlight = true;
    try {
      final job = await _service.getStatus(jobId);
      // Drop stale responses after stop/restart/navigation.
      if (_activeJobId != jobId) return;
      _consecutivePollFailures = 0;
      if (_lastStage != job.stage) {
        _analytics.logEvent(VideoAnalyticsService.analysisStageChanged, {
          'job_id': job.jobId,
          'stage': job.stage,
          'status': job.status,
        });
        _lastStage = job.stage;
      }
      state = AsyncData(job);
      if (job.isTerminal) {
        await stopPolling(keepState: true);
        _emitTerminalAnalytics(job);
      }
    } catch (e, st) {
      if (_activeJobId != jobId) return;
      _consecutivePollFailures += 1;
      final fatal = e is VideoEngineV2Exception &&
          _isFatalPollError(e.errorCode);
      if (fatal || _consecutivePollFailures >= _maxTransientFailures) {
        state = AsyncError(e, st);
        await stopPolling(keepState: true);
      }
      // Transient blip: keep last good job state and keep polling.
    } finally {
      _tickInFlight = false;
    }
  }

  bool _isFatalPollError(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'UNAUTHORIZED':
      case 'AUTHENTICATION_EXPIRED':
      case 'AUTH_REQUIRED':
      case 'FORBIDDEN':
      case 'NOT_OWNER':
      case 'NOT_FOUND':
        return true;
      default:
        return false;
    }
  }

  void _emitTerminalAnalytics(AnalysisJob job) {
    if (job.isSuccess) {
      _analytics.logEvent(VideoAnalyticsService.analysisCompleted, {
        'job_id': job.jobId,
        'status': job.status,
        'stage': job.stage,
      });
    } else if (job.isFailed) {
      _analytics.logEvent(VideoAnalyticsService.analysisFailed, {
        'job_id': job.jobId,
        'error_code': job.errorCode,
        'stage': job.stage,
      });
    } else if (job.isCancelled) {
      _analytics.logEvent(VideoAnalyticsService.analysisCancelled, {
        'job_id': job.jobId,
      });
    }
  }

  Future<void> cancelActiveJob() async {
    final jobId = _activeJobId;
    if (jobId == null) return;
    final job = await _service.cancelJob(jobId);
    _analytics.logEvent(VideoAnalyticsService.analysisCancelled, {
      'job_id': jobId,
    });
    state = AsyncData(job);
    await stopPolling(keepState: true);
  }

  Future<AnalysisJob> retryActiveJob() async {
    final jobId = _activeJobId ?? state.valueOrNull?.jobId;
    if (jobId == null) {
      throw VideoEngineV2Exception(
        VideoEngineV2Service.userMessageForErrorCode('ANALYSIS_FAILED'),
        errorCode: 'ANALYSIS_FAILED',
      );
    }
    final job = await _service.retryJob(jobId);
    _analytics.logEvent(VideoAnalyticsService.analysisRetry, {
      'job_id': jobId,
    });
    return startPolling(job.jobId);
  }

  Future<void> stopPolling({bool keepState = false}) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeJobId = null;
    _tickInFlight = false;
    _consecutivePollFailures = 0;
    if (!keepState) {
      state = const AsyncData(null);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final videoEngineV2JobProvider =
    StateNotifierProvider<VideoEngineV2JobNotifier, AsyncValue<AnalysisJob?>>(
  VideoEngineV2JobNotifier.new,
);
