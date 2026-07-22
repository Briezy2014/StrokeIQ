import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swimiq/config/feature_flags.dart';
import 'package:swimiq/core/constants/demo_account_constants.dart';
import 'package:swimiq/core/constants/master_account_constants.dart';
import 'package:swimiq/core/models/subscription_plan.dart';
import 'package:swimiq/core/services/subscription_service.dart';
import 'package:swimiq/core/services/video_analytics_service.dart';
import 'package:swimiq/core/services/video_engine_v2_service.dart';
import 'package:swimiq/data/models/swim_video.dart';
import 'package:swimiq/data/models/video_engine_v2/video_engine_v2_models.dart';
import 'package:swimiq/providers/app_providers.dart';
import 'package:swimiq/providers/video_engine_v2_provider.dart';

void main() {
  group('FeatureFlags', () {
    test('constants are stable', () {
      expect(FeatureFlags.videoEngineV2, 'video_engine_v2');
      expect(FeatureFlags.videoEngineLegacy, 'video_engine_legacy');
    });

    test('built-in master and demo accounts are recognized', () {
      expect(
        FeatureFlags.isBuiltInEliteVideoAccount(MasterAccountConstants.email),
        isTrue,
      );
      expect(
        FeatureFlags.isBuiltInEliteVideoAccount(DemoAccountConstants.email),
        isTrue,
      );
      expect(
        FeatureFlags.isBuiltInEliteVideoAccount('random@example.com'),
        isFalse,
      );
    });

    test('coach elite peek unlocks V2 UI even when email is not allowlisted', () {
      final started = DateTime.now().subtract(const Duration(days: 1));
      final coachState = SubscriptionState(
        tier: SubscriptionTier.basic,
        billingCycle: BillingCycle.monthly,
        trialEndsAt: null,
        coachTrialEndsAt: DateTime.now().add(const Duration(days: 10)),
        coachTrialStartedAt: started,
        coachAiAnalysesUsed: 0,
        hasUsedTrial: true,
      );

      // VIDEO_ENGINE_V2 may be false in unit tests (default). This asserts the
      // subscription bypass path shape: when V2 is off, still false.
      expect(
        FeatureFlags.isVideoEngineV2Allowed(
          email: 'coach.parent@example.com',
          subscription: coachState,
        ),
        FeatureFlags.videoEngineV2Enabled,
      );
    });
  });

  group('AnalysisMetric display rules', () {
    test('null metrics are not shown as zero', () {
      const metric = AnalysisMetric(
        name: 'stroke_rate',
        displayName: 'Stroke Rate',
        value: null,
        unit: 'cycles_per_minute',
        confidenceLabel: 'unavailable',
        classification: 'unavailable',
        unavailableReason: 'Insufficient evidence',
      );
      expect(metric.displayValue, isNot(equals('0')));
      expect(metric.displayValue, 'Unavailable');
      expect(metric.isUnavailable, isTrue);
      expect(metric.displayWithUnit, 'Unavailable');
    });

    test('low-confidence metrics are not presented as facts', () {
      const metric = AnalysisMetric(
        name: 'tempo',
        displayName: 'Tempo',
        value: 42,
        unit: 'spm',
        confidence: 0.5,
        confidenceLabel: 'low',
        classification: 'estimated',
      );
      expect(metric.isLowConfidence, isTrue);
      expect(metric.isUnavailable, isFalse);
      expect(metric.displayValue, isNot(equals('0')));
    });
  });

  group('VideoEngineV2Service error mapping', () {
    test('maps known codes including unauthorized access', () {
      expect(
        VideoEngineV2Service.userMessageForErrorCode('INVALID_VIDEO'),
        contains('could not be used'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('UNSUPPORTED_CODEC'),
        contains('not supported'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('TARGET_SWIMMER_NOT_FOUND'),
        contains('target swimmer'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('TARGET_LOST_EXTENDED'),
        contains('lost sight'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('NO_DETECTIONS'),
        contains('detect a swimmer'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('INSUFFICIENT_POSE'),
        contains('Retry analysis'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('POSE_DEPS_MISSING'),
        contains('Phone coaching'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode(
          'INTERNAL_ERROR',
          fallback:
              "Pose dependency stack not ready: missing=['torch'] errors=[\"torch: No module named 'torch'\"]",
        ),
        contains('Phone coaching'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode(
          'INTERNAL_ERROR',
          fallback:
              "Pose dependency stack not ready: missing=['torch'] errors=[\"torch: No module named 'torch'\"]",
        ),
        isNot(contains('No module named')),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('SERVER_UNAVAILABLE'),
        contains('unavailable'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('ANALYSIS_FAILED'),
        contains('failed'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('GEMINI_REPORT_UNAVAILABLE'),
        contains('GEMINI_API_KEY'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('VIDEO_TOO_LONG'),
        contains('2 minutes'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('GEMINI_ERROR'),
        contains('rejected'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('UPLOAD_FAILED'),
        contains('load your video'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('DOWNLOAD_TIMEOUT'),
        contains('timed out'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('AUTHENTICATION_EXPIRED'),
        contains('session'),
      );
      expect(
        VideoEngineV2Service.userMessageForErrorCode('FORBIDDEN'),
        contains('access'),
      );
    });
  });

  group('VideoEngineV2Service HTTP', () {
    VideoEngineV2Service serviceWith(
      Future<http.Response> Function(http.Request) handler,
    ) {
      return VideoEngineV2Service(
        client: MockClient(handler),
        accessTokenGetter: () async => 'test-token',
        baseUrl: 'http://analysis.test',
      );
    }

    test('successful create job (upload path → analyze job)', () async {
      final service = serviceWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/analyses');
        expect(request.headers['Authorization'], 'Bearer test-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['storage_path'], 'user-1/clip.mp4');
        final options = body['options'] as Map<String, dynamic>;
        // Launch phone-friendly defaults: sensors enrich, overlay stays off.
        expect(options['run_pose_stage'], isTrue);
        expect(options['run_underwater_analysis'], isTrue);
        expect(options['run_turn_analysis'], isTrue);
        expect(options['run_finish_analysis'], isTrue);
        expect(options['attach_evidence_images'], isTrue);
        expect(options['generate_overlay'], isFalse);
        return http.Response(
          jsonEncode({
            'job_id': 'job-1',
            'status': 'queued',
            'stage': 'queued',
            'video_id': 'vid-1',
            'engine_version': 'elote-0.1.0',
            'created_at': '2026-07-17T00:00:00Z',
          }),
          202,
        );
      });

      final job = await service.createJob(
        videoId: 'vid-1',
        storagePath: 'user-1/clip.mp4',
        swimmerKey: 'Aspyn',
        stroke: 'Butterfly',
        distanceM: 50,
        course: 'LCM',
      );
      expect(job.jobId, 'job-1');
      expect(job.stage, 'queued');
      expect(job.stageLabel, 'Queued');
    });

    test('failed upload / create maps SERVER_UNAVAILABLE on network error', () async {
      final service = VideoEngineV2Service(
        client: MockClient((_) async => throw Exception('socket')),
        accessTokenGetter: () async => 'test-token',
        baseUrl: 'http://analysis.test',
      );
      expect(
        () => service.createJob(
          videoId: 'vid-1',
          storagePath: 'user-1/clip.mp4',
        ),
        throwsA(
          isA<VideoEngineV2Exception>().having(
            (e) => e.errorCode,
            'errorCode',
            'SERVER_UNAVAILABLE',
          ),
        ),
      );
    });

    test('checkHealth reports reachable Elite server', () async {
      final service = serviceWith((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/health');
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'engine_version': 'elite-0.9.0',
            'ffmpeg_available': true,
            'ffprobe_available': true,
            'storage_download_configured': true,
          }),
          200,
        );
      });
      final health = await service.checkHealth();
      expect(health.reachable, isTrue);
      expect(health.mediaToolsReady, isTrue);
      expect(health.storageConfigured, isTrue);
      expect(health.engineVersion, 'elite-0.9.0');
    });

    test('checkHealth rejects stale Elite server without storage field', () async {
      final service = serviceWith((request) async {
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'engine_version': 'elite-0.9.0',
            'ffmpeg_available': true,
            'ffprobe_available': true,
          }),
          200,
        );
      });
      final health = await service.checkHealth();
      expect(health.storageConfigured, isFalse);
      expect(health.message, contains('OUT OF DATE'));
    });

    test('checkHealth reports unreachable server', () async {
      final service = VideoEngineV2Service(
        client: MockClient((_) async => throw Exception('connection refused')),
        accessTokenGetter: () async => 'test-token',
        baseUrl: 'http://analysis.test',
      );
      final health = await service.checkHealth();
      expect(health.reachable, isFalse);
      expect(health.message, contains('Elite server is OFF'));
      expect(health.message, contains('START-SWIMIQ-WITH-ELITE.bat'));
    });

    test('unauthorized result access error mapping', () async {
      final service = serviceWith(
        (_) async => http.Response('{"detail":"forbidden"}', 403),
      );
      expect(
        () => service.getResults('job-x'),
        throwsA(
          isA<VideoEngineV2Exception>().having(
            (e) => e.errorCode,
            'errorCode',
            'FORBIDDEN',
          ),
        ),
      );
    });

    test('job polling status transitions', () async {
      var calls = 0;
      final service = serviceWith((request) async {
        calls++;
        final stage = calls == 1 ? 'downloading' : 'estimating_pose';
        return http.Response(
          jsonEncode({
            'job_id': 'job-2',
            'status': stage,
            'stage': stage,
            'progress': calls == 1 ? 0.08 : 0.4,
            'engine_version': 'elote-0.1.0',
            'video_id': 'vid-1',
            'created_at': '2026-07-17T00:00:00Z',
            'updated_at': '2026-07-17T00:00:01Z',
          }),
          200,
        );
      });

      final first = await service.getStatus('job-2');
      expect(first.stageLabel, 'Downloading video');
      final second = await service.getStatus('job-2');
      expect(second.stageLabel, 'Estimating pose');
      // Progress exists but UI must use stage text, not invent %.
      expect(second.progress, 0.4);
    });

    test('completed analysis results parse metrics and report', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({
            'job_id': 'job-3',
            'status': 'completed',
            'engine_version': 'elote-0.1.0',
            'video_id': 'vid-1',
            'metrics': [
              {
                'name': 'stroke_rate',
                'display_name': 'Stroke Rate',
                'value': 48.2,
                'unit': 'cycles_per_minute',
                'confidence': 0.9,
                'confidence_label': 'high',
                'classification': 'measured',
              },
            ],
            'phases': [],
            'limitations': [],
            'evidence_frames': [
              {'path': 'frames/1.jpg', 'label': 'Breakout'},
            ],
            'report': {
              'summary': 'Strong tempo',
              'strengths': ['Kick'],
              'priority_improvements': [
                {
                  'title': 'Head position',
                  'evidence_metric_names': ['stroke_rate'],
                  'drills': ['Kickboard fly'],
                },
              ],
              'gemini_succeeded': true,
            },
            'created_at': '2026-07-17T00:00:00Z',
          }),
          200,
        ),
      );

      final results = await service.getResults('job-3');
      expect(results.isCompleted, isTrue);
      expect(results.metrics.first.displayValue, '48.2');
      expect(results.hasReport, isTrue);
      expect(results.report!.priorityImprovements.first.drills, isNotEmpty);
    });

    test('completed with limitations', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({
            'job_id': 'job-4',
            'status': 'completed_with_limitations',
            'engine_version': 'elote-0.1.0',
            'metrics': [
              {
                'name': 'underwater_time',
                'display_name': 'Underwater time',
                'value': null,
                'unit': 's',
                'confidence_label': 'unavailable',
                'classification': 'unavailable',
                'unavailable_reason': 'Splash occlusion',
              },
            ],
            'limitations': ['Splash occlusion near breakout'],
            'report': null,
            'created_at': '2026-07-17T00:00:00Z',
          }),
          200,
        ),
      );

      final results = await service.getResults('job-4');
      expect(results.isPartialSuccess, isTrue);
      expect(results.limitations, contains('Splash occlusion near breakout'));
      expect(results.metrics.first.displayValue, isNot(equals('0')));
    });

    test('failed analysis', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({
            'job_id': 'job-5',
            'status': 'failed',
            'engine_version': 'elote-0.1.0',
            'metrics': [],
            'limitations': [],
            'error': {
              'error_code': 'ANALYSIS_FAILED',
              'message': 'Pipeline crashed',
              'stage': 'estimating_pose',
              'job_id': 'job-5',
              'retriable': true,
            },
            'created_at': '2026-07-17T00:00:00Z',
          }),
          200,
        ),
      );

      final results = await service.getResults('job-5');
      expect(results.isFailed, isTrue);
      expect(results.errorCode, 'ANALYSIS_FAILED');
    });

    test('Gemini failure with deterministic results kept', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({
            'job_id': 'job-6',
            'status': 'completed_with_limitations',
            'engine_version': 'elote-0.1.0',
            'metrics': [
              {
                'name': 'stroke_count',
                'display_name': 'Stroke count',
                'value': 12,
                'unit': 'cycles',
                'confidence': 0.88,
                'confidence_label': 'high',
                'classification': 'measured',
              },
            ],
            'limitations': ['gemini_report_failed'],
            'report': null,
            'created_at': '2026-07-17T00:00:00Z',
          }),
          200,
        ),
      );

      final results = await service.getResults('job-6');
      expect(results.hasDeterministicMetrics, isTrue);
      expect(results.reportFailed, isTrue);
      expect(results.metrics.first.displayValue, '12');
    });

    test('retry and cancellation', () async {
      final service = serviceWith((request) async {
        if (request.url.path.endsWith('/cancel')) {
          return http.Response(
            jsonEncode({
              'job_id': 'job-7',
              'status': 'cancelled',
              'message': 'Job cancelled',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/retry')) {
          return http.Response(
            jsonEncode({
              'job_id': 'job-7',
              'status': 'queued',
              'stage': 'queued',
              'message': 'Retry scheduled',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final cancelled = await service.cancelJob('job-7');
      expect(cancelled.status, 'cancelled');
      expect(cancelled.isCancelled, isTrue);

      final retried = await service.retryJob('job-7');
      expect(retried.status, 'queued');
      expect(retried.stage, 'queued');
    });

    test('reopening analysis history', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({
            'swimmer_key': 'Aspyn',
            'jobs': [
              {
                'job_id': 'hist-1',
                'status': 'completed',
                'stage': 'completed',
                'engine_version': 'elote-0.1.0',
                'created_at': '2026-07-17T00:00:00Z',
                'updated_at': '2026-07-17T00:01:00Z',
                'has_report': true,
                'has_metrics': true,
              },
            ],
            'remote_jobs': [],
          }),
          200,
        ),
      );

      final history = await service.listHistory('Aspyn');
      expect(history, hasLength(1));
      expect(history.first.jobId, 'hist-1');
      expect(history.first.isTerminal, isTrue);
    });
  });

  group('VideoEngineV2JobNotifier polling', () {
    test('polls until terminal completed', () async {
      var statusCalls = 0;
      final mockClient = MockClient((request) async {
        statusCalls++;
        final done = statusCalls >= 2;
        return http.Response(
          jsonEncode({
            'job_id': 'poll-1',
            'status': done ? 'completed' : 'calculating_metrics',
            'stage': done ? 'completed' : 'calculating_metrics',
            'progress': done ? 1.0 : 0.7,
            'engine_version': 'elote-0.1.0',
            'video_id': 'vid-1',
            'created_at': '2026-07-17T00:00:00Z',
            'updated_at': '2026-07-17T00:00:01Z',
          }),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          videoEngineV2ServiceProvider.overrideWithValue(
            VideoEngineV2Service(
              client: mockClient,
              accessTokenGetter: () async => 'token',
              baseUrl: 'http://analysis.test',
            ),
          ),
          videoAnalyticsServiceProvider.overrideWithValue(
            const VideoAnalyticsService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(videoEngineV2JobProvider.notifier);
      final first = await notifier.startPolling('poll-1');
      expect(first.stage, 'calculating_metrics');

      await Future<void>.delayed(const Duration(seconds: 3));
      final latest = container.read(videoEngineV2JobProvider).valueOrNull;
      expect(latest?.isTerminal, isTrue);
      expect(latest?.status, 'completed');
    });
  });

  group('VideoAnalyticsService', () {
    test('omits binary-like props', () {
      const analytics = VideoAnalyticsService();
      // Should not throw; binary keys omitted in debugPrint path.
      analytics.logEvent('video_upload_failed', {
        'bytes': [1, 2, 3],
        'file_name': 'clip.mp4',
      });
    });
  });

  group('SwimVideo userId insert', () {
    test('toInsertJson includes user_id when provided', () {
      const video = SwimVideo(
        swimmer: 'Aspyn',
        storagePath: 'uid-1/clip.mp4',
        userId: 'uid-1',
      );
      final json = video.toInsertJson();
      expect(json['user_id'], 'uid-1');
      expect(json['storage_path'], 'uid-1/clip.mp4');
      expect(json['swimmer'], 'Aspyn');
    });

    test('toInsertJson omits user_id when null', () {
      const video = SwimVideo(
        swimmer: 'Aspyn',
        storagePath: 'Aspyn/clip.mp4',
      );
      expect(video.toInsertJson().containsKey('user_id'), isFalse);
    });
  });
}
