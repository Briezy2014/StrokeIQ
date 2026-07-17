# Elote Video Lab — Video Engine Rebuild Plan

**Status:** Planning only. No application code changes in this deliverable.  
**Product surface name:** **Elote Video Lab** (replaces the current Video / Video Lab analysis tab experience).  
**Primary technical decision:** Use **RTMPose WholeBody** as the primary pose model. Do **not** use Gemini as the measurement engine. Do **not** use MediaPipe as the production foundation.  
**Companion audit:** [`docs/video_engine_audit.md`](./video_engine_audit.md)

---

## 0. Destination architecture (non-negotiable)

```
Flutter mobile app (Elote Video Lab UI)
  → Supabase Storage video upload (preserve original)
  → Python FastAPI analysis backend (services/video_analysis/)
      → FFmpeg/OpenCV preprocessing
      → RTMDet swimmer detection + tracking
      → RTMPose WholeBody pose estimation
      → Pose filtering / temporal smoothing
      → Swimming event detection
      → Deterministic biomechanics calculations
      → Confidence + evidence validation
      → Structured JSON results (Pydantic)
      → Gemini coaching interpretation ONLY
  → Results returned to Flutter + stored in Supabase
```

Gemini may interpret validated structured metrics and write the athlete-friendly report.  
Gemini must **not** count strokes, compute joint angles, identify exact timestamps, measure tempo, identify breakouts, count underwater kicks, or determine turn durations.

MediaPipe may exist later only as an optional fallback/diagnostic adapter.

---

## 1. Files to retain / replace / deprecate

### Retain (Flutter + platform — preserve unless absolutely required)

| Area | Paths / notes |
|------|----------------|
| Auth | Existing Supabase auth flow |
| Subscriptions / Elite gate | Keep gating; point AI analysis at new job API later |
| Athlete profiles / passport | Intact |
| Non-video features | Dashboard, log, PBs, goals, meets, settings |
| Upload primitives | `VideoStorageService`, `swim_videos` insert — adapt, don’t rewrite |
| Consent | `AiDataConsentDialog` concept remains |
| Models shell | `SwimVideo` as upload registry; analysis models will evolve |
| Branding / nav shell | Rename Video → **Elote Video Lab** in Milestone 9 (not now) |

### Replace (analysis engine)

| Current | Replacement |
|---------|-------------|
| `supabase/functions/analyze-swim-video` Gemini-as-measurer | FastAPI job pipeline + Gemini report stage only |
| Synchronous `GeminiSwimAnalysisService` full-wait invoke | Async job create + poll (`/v1/analyses`) |
| Silent `AiSwimAnalysisService` success fallback | Explicit failed / completed_with_limitations states; no fake success |
| Stub MediaPipe pose as “body mechanics” | RTMPose WholeBody behind `PoseEstimator` interface |
| Flat coaching scores without evidence | Metric contract with confidence, method, frames, quality flags |

### Deprecate (do not delete in Milestone 1; mark obsolete)

| Item | Reason |
|------|--------|
| `AiSwimAnalysisService` as user-facing “AI analysis” | Notes heuristics; may remain offline diagnostic only |
| Pose stub implementations as production path | Keep only if wrapping a future MediaPipe fallback adapter |
| `swimiq/docs/POSE_AND_GEMINI.md` accuracy claims | Rewrite after new engine lands |
| Streamlit “Video Lab” nav as product path | Not the Flutter engine |

---

## 2. Proposed directory structure

New isolated service (create in Phase 2 / Milestone 1 scaffolding when implementation begins):

```
services/video_analysis/
  app/
    main.py
    config.py
    api/
      routes/
        health.py
        analysis.py
        jobs.py
      schemas/
        requests.py
        responses.py
        metrics.py
        events.py
    services/
      video_validator.py
      video_preprocessor.py
      swimmer_detector.py
      swimmer_tracker.py
      pose_estimator.py          # interface
      pose_smoother.py
      camera_calibration.py
      pool_calibration.py
      stroke_classifier.py
      phase_detector.py
      start_analyzer.py
      underwater_analyzer.py
      stroke_analyzer.py
      turn_analyzer.py
      finish_analyzer.py
      confidence_engine.py
      report_generator.py        # Gemini narrative only
      result_store.py
    models/
      model_registry.py
      rtmpose_adapter.py         # primary PoseEstimator
      detector_adapter.py        # RTMDet
      # optional later: mediapipe_adapter.py (fallback only)
    domain/
      landmarks.py
      observations.py
      phases.py
      metrics.py
    utils/
      geometry.py
      signals.py
      timestamps.py
      logging.py
  tests/
    unit/
    integration/
    fixtures/
  scripts/
  Dockerfile
  requirements.txt
  .env.example
  README.md
```

Artifact layout (runtime, not committed):

```
analysis_artifacts/{job_id}/
  metadata.json
  frames/
  pose/
  events/
  results/
```

Flutter app stays under `swimiq/`. Supabase migrations for new tables live under `swimiq/supabase/migrations/` (or a dedicated migrations folder agreed at implementation time).

---

## 3. Proposed API contract

Base URL: analysis service (separate host). Auth: user JWT validated server-side; service uses Supabase service role only on backend.

### Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/health` | Liveness + engine version + dependency checks |
| `POST` | `/v1/analyses` | Create analysis job from secure Supabase video reference |
| `GET` | `/v1/analyses/{job_id}` | Status + progress + current stage |
| `GET` | `/v1/analyses/{job_id}/results` | Validated structured results (+ report if ready) |
| `POST` | `/v1/analyses/{job_id}/cancel` | Cancel eligible job |
| `POST` | `/v1/analyses/{job_id}/retry` | Retry from failed stage when safe |

Mobile must **not** wait synchronously for full analysis.

### Job states (explicit)

```
queued
validating
preprocessing
detecting_swimmer
estimating_pose
detecting_events
calculating_metrics
validating_results
generating_report
completed
completed_with_limitations
failed
```

---

## 4. Proposed API schemas (Pydantic / JSON)

### 4.1 `POST /v1/analyses` request

```json
{
  "video_id": "uuid",
  "storage_bucket": "swim-videos",
  "storage_path": "athlete/uuid.mp4",
  "athlete": {
    "swimmer_key": "string",
    "display_name": "string",
    "age_group": "string|null"
  },
  "event": {
    "stroke": "butterfly|freestyle|backstroke|breaststroke|im|unknown",
    "distance_m": 50,
    "course": "LCM|SCM|SCY",
    "title": "string|null",
    "notes": "string|null"
  },
  "options": {
    "target_track_id": null,
    "view_hint": "side|diagonal_side|end|deck|underwater_side|underwater_front|mixed|unknown",
    "generate_overlay": false,
    "generate_gemini_report": true
  }
}
```

### 4.2 Job status response (`GET /v1/analyses/{job_id}`)

```json
{
  "job_id": "uuid",
  "status": "estimating_pose",
  "progress": 0.42,
  "stage": "estimating_pose",
  "engine_version": "elote-0.1.0",
  "video_id": "uuid",
  "error": null,
  "retry_count": 0,
  "created_at": "2026-07-16T00:00:00Z",
  "updated_at": "2026-07-16T00:00:00Z"
}
```

### 4.3 Results response (`GET /v1/analyses/{job_id}/results`)

```json
{
  "job_id": "uuid",
  "status": "completed_with_limitations",
  "engine_version": "elote-0.1.0",
  "video": {
    "duration_ms": 0,
    "fps": 0.0,
    "width": 0,
    "height": 0,
    "view": "side",
    "quality_score": 0.0
  },
  "athlete": {
    "track_id": "string",
    "tracking_confidence": 0.0
  },
  "stroke": {
    "predicted": "butterfly",
    "confidence": 0.0
  },
  "phases": [],
  "metrics": [],
  "limitations": [],
  "evidence_frames": [],
  "model_versions": {},
  "report": null,
  "created_at": "2026-07-16T00:00:00Z"
}
```

### 4.4 Metric object

```json
{
  "name": "stroke_rate",
  "display_name": "Stroke Rate",
  "value": 42.8,
  "unit": "cycles_per_minute",
  "confidence": 0.91,
  "confidence_label": "high",
  "classification": "measured",
  "method": "wrist-cycle peak detection",
  "start_ms": 4320,
  "end_ms": 12140,
  "supporting_frames": [130, 156, 182],
  "quality_flags": [],
  "comparison": null,
  "unavailable_reason": null
}
```

Rules:

- Every metric: `value`, `unit`, `confidence` (0–1), `method`, supporting timestamps/frames, `quality_flags`.
- Use `null` value + `unavailable_reason` rather than inventing unreliable numbers.
- Confidence labels: high ≥0.85, moderate ≥0.65, low ≥0.40, unavailable below 0.40 / insufficient evidence.
- Classification: `measured` | `estimated` | `observational` | `unavailable`.

### 4.5 Phase / event object

```json
{
  "name": "breakout",
  "start_ms": 2100,
  "end_ms": 2100,
  "start_frame": 63,
  "end_frame": 63,
  "confidence": 0.78,
  "editable": true,
  "quality_flags": ["splash_interference"],
  "evidence_frames": [60, 63, 66]
}
```

### 4.6 Gemini report object (post-metrics only)

```json
{
  "summary": "string",
  "strengths": ["...", "...", "..."],
  "priority_improvements": [
    {
      "title": "string",
      "evidence_metric_names": ["stroke_rate"],
      "drills": ["...", "..."]
    }
  ],
  "race_recommendations": ["..."],
  "limitations_statement": "string",
  "model": "gemini-...",
  "created_at": "..."
}
```

If Gemini fails after deterministic metrics succeed: job may be `completed_with_limitations` with metrics present and `report: null` — **never** invent a coaching report.

### 4.7 Error object

```json
{
  "error_code": "VIDEO_TOO_LARGE|UNSUPPORTED_CODEC|POSE_FAILED|...",
  "message": "string",
  "stage": "validating",
  "job_id": "uuid",
  "retriable": true
}
```

Logging (all stages): stage, video ID, job ID, error type, message, stack trace. No silent swallows.

---

## 5. Database changes (proposed)

New tables (names per spec):

| Table | Purpose |
|-------|---------|
| `video_analysis_jobs` | Job lifecycle, status, engine/model versions, error_code, retry_count, ownership |
| `video_analysis_events` | Detected phases/events with editable boundaries |
| `video_analysis_metrics` | Per-metric rows with confidence + evidence |
| `video_analysis_artifacts` | Paths/URLs to metadata, pose JSON, overlays, frames |
| `video_analysis_reports` | Gemini narrative JSON (optional; not source of truth) |
| `video_analysis_feedback` | Coach/athlete corrections |
| `model_versions` | Registry of detector/pose/report models |

Required columns (conceptual):

- User ownership + athlete ownership
- `created_at` / `updated_at`
- `engine_version`, model versions
- `processing_status` / job status enum
- `error_code`, `retry_count`
- Confidence fields where applicable
- Soft deletion where appropriate
- RLS policies scoped to owner (replace open `USING (true)` for new tables; plan hardening of legacy video tables)

**Do not** put service-role credentials in Flutter.

Existing `swim_videos` / `swim_video_analyses` remain during migration; new engine writes primarily to job/metric tables. Legacy analysis rows can be marked with engine tags; dual-read period optional.

---

## 6. Dependency and compatibility matrix

| Component | Target | Notes / compatibility |
|-----------|--------|------------------------|
| Python | **3.11** | Pin in Docker image |
| FastAPI + Pydantic + Uvicorn/Gunicorn | Latest stable compatible with 3.11 | API layer |
| OpenCV (cv2) | 4.x | Preprocess / visualization |
| FFmpeg / ffprobe | System binary in Docker | Validation + normalize; not optional |
| NumPy / SciPy | Compatible with PyTorch build | Signals, filtering |
| pandas | Optional | Tabular exports / golden eval |
| PyTorch | CUDA image for GPU workers; CPU image for CI | Pin CUDA/cuDNN carefully |
| MMPose + RTMPose WholeBody | Primary pose | Behind `PoseEstimator` interface |
| RTMDet | Primary person/swimmer detector | Behind detector interface |
| ONNX Runtime | Optional deploy optimization | After native path works |
| Supabase Python SDK | Backend only | Storage download + DB writes |
| Google Gen AI SDK | Report stage only | Secrets server-side |
| Ultralytics YOLO | **Not for production** unless licensing explicitly approved | Document if ever considered |
| MediaPipe | Optional fallback adapter only | Not production foundation |
| Flutter packages | Keep existing upload/playback stack | Add HTTP job client later (M9) |
| Edge Function Gemini measurer | Retire after cutover | Do not extend |

**Licensing note:** Prefer RTMDet/RTMPose/MMPose licensing review before commercial App Store distribution; explicitly avoid Ultralytics YOLO in production without written approval.

**Incompatibility with current repo:** Root `requirements.txt` is Streamlit-only. New service must have its own `services/video_analysis/requirements.txt` and Docker image. Do not mix Streamlit and MMPose into one env.

---

## 7. Migration strategy

1. **Phase A (this PR):** Docs only — audit + rebuild plan.
2. **Phase B (Milestone 1):** Stand up FastAPI service with health, job create/status stubs, video validation, metadata extraction, logging — **no Flutter rewrite**.
3. **Phase C (M2–M7):** CV + biomechanics milestones with tests and diagnostics; store artifacts under `analysis_artifacts/`.
4. **Phase D (M8):** Gemini report from validated metrics only.
5. **Phase E (M9):** Flutter Elote Video Lab integration — async poll, results UI, failure UI, limitations UI; remove silent V1 success path; rename tab/header.
6. **Cutover:** Feature-flag new engine; keep Edge Function temporarily for rollback; then deprecate.
7. **Data:** Keep original videos in `swim-videos`; never overwrite originals; write new job tables; optionally backfill nothing (historical Gemini notes remain historical).

---

## 8. Deployment requirements

- Separate container/service for `services/video_analysis` (CPU first; GPU for pose at scale).
- FFmpeg installed in image.
- Model weights fetched at build/start via `model_registry` (not committed if large).
- Secrets: Supabase service role, Gemini key, signing/JWT validation — environment only.
- Artifact storage: local volume initially; Supabase Storage or object store later for multi-instance.
- Horizontal scaling: job queue (DB-backed first; Redis/Celery optional later).
- Health checks for orchestrator readiness.
- Egress to Gemini only from backend; Flutter never holds that key.

---

## 9. Migration risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Silent V1 fallback hides real failures during dual-run | False confidence | Remove success path for notes fallback before Elote cutover |
| Open RLS on legacy video tables | Data leakage | New tables with owner RLS; harden legacy in dedicated migration |
| Public `swim-videos` bucket | Unauthorized playback | Private bucket + signed URLs migration |
| Edge Function path IDOR | Cross-user video download | Ownership check; retire function |
| MMPose/RTMPose install fragility | Blocked M2–M3 | Isolate deps in Docker; pin versions; document install command |
| GPU availability in CI | No pose in CI | CPU models or fixture-based unit tests; GPU smoke separate |
| Phone rotation / VFR videos | Bad timestamps | Milestone 1 ffprobe validation + normalize |
| Multi-swimmer lane confusion | Wrong athlete metrics | M2 tracking + user track selection |
| Splash/underwater domain gap | Low pose coverage | Confidence engine + unavailable metrics; golden set later |
| Gemini inventing numbers | Unsafe coaching | Send only validated metrics; schema forbid new measurements |
| 18 MB / sync timeout habits | Bad UX | Async jobs from day one |
| Scope creep (all metrics as placeholders) | Untrustworthy UI | Only ship tested metrics; others `unavailable` with reason |
| Ultralytics accidental dependency | License conflict | Ban in requirements review |
| Mixing Streamlit and CV envs | Broken installs | Separate `services/video_analysis` |

---

## 10. Acceptance tests (program-level)

### Deterministic engine

- Unit: angles, timestamps, frame conversion, smoothing, interpolation limits, peak/cycle detection, confidence, null handling.
- Integration: valid/corrupt/rotated/VFR/multi-swimmer/occlusion/low-light/splash/short/unsupported codec/failed pose/Gemini down/Supabase down.
- Golden set (Phase 16): labeled cycles, breakout, kicks, turns, wall contact, breathing, stroke, target swimmer, unusable ranges → MAE, count errors, precision/recall, coverage, calibration.

### Product rules

- No successful coaching report when CV failed.
- Metrics include evidence + confidence.
- Original video preserved.
- Stages independently testable.
- Butterfly first production metric set (count, rate, cycle consistency, breathing, UW duration, breakout, UW kicks, entry symmetry, turn framework, finish timing, confidence/evidence) — only after each is validated.

### Milestone gate

Do not advance milestones without: automated tests, reproducible test command, real diagnostic output, documented acceptance criteria, **no placeholder success response**.

---

## 11. Implementation order (locked)

| Milestone | Scope |
|-----------|--------|
| **M1** | Video validation, metadata extraction, job creation, logging, health endpoint |
| **M2** | RTMDet detection, tracking, crops, tracking diagnostics |
| **M3** | RTMPose: one image → 5s clip → full clip |
| **M4** | Raw + smoothed pose JSON + skeleton overlay |
| **M5** | Butterfly cycles: count, rate, breathing estimate, confidence |
| **M6** | Underwater duration, breakout, UW kick count |
| **M7** | Turn + finish event framework |
| **M8** | Gemini structured coaching from validated metrics only |
| **M9** | Flutter Elote Video Lab: polling, results/failure/limitations UI |

---

## 12. Exact Milestone 1 task list

**Goal:** Isolated analysis service foundation. No Flutter rewrite. No RTMPose yet. No Gemini measurement. No placeholder “analysis succeeded” coaching output.

### 12.1 Scaffolding

1. Create `services/video_analysis/` tree as specified (empty modules OK if imported/tested).
2. Add `requirements.txt` for M1 only: FastAPI, Uvicorn, Pydantic, NumPy (minimal); document FFmpeg system dependency.
3. Add `Dockerfile` with Python 3.11 + FFmpeg/ffprobe.
4. Add `.env.example` (no secrets committed).
5. Add service `README.md` with run/test commands.

### 12.2 Config + logging

6. Implement `app/config.py` (env-driven settings, artifact root, max upload size, min resolution/fps).
7. Implement structured logging in `app/utils/logging.py` with stage, video_id, job_id, error type, message, stack.

### 12.3 API

8. `GET /health` → status, engine version, ffmpeg/ffprobe availability.
9. `POST /v1/analyses` → create job record (in-memory or local JSON/SQLite acceptable for M1), return `job_id`, status `queued`→`validating`.
10. `GET /v1/analyses/{job_id}` → status/progress/stage.
11. `GET /v1/analyses/{job_id}/results` → for M1, return validation/metadata results only (not a coaching report).
12. Stub cancel/retry routes with correct contracts (may return 501 only if documented; prefer real cancel for queued jobs).

### 12.4 Validation + preprocessing (M1 core)

13. `video_validator.py` via ffprobe: MIME/codec, duration, width/height, fps, frame count, rotation, corrupt streams, max size, min resolution, min fps.
14. Reject invalid videos with explicit error codes; status `failed` (never fake success).
15. `video_preprocessor.py` (minimal for M1): correct rotation metadata handling, write `analysis_artifacts/{job_id}/metadata.json`, preserve original path reference; optional proxy generation can be thin if tested.
16. Do **not** downsample to 1 fps.

### 12.5 Schemas + persistence

17. Pydantic schemas for requests/responses/job status/errors.
18. Job state machine with allowed transitions for M1 stages: `queued` → `validating` → `preprocessing` → `completed` | `completed_with_limitations` | `failed`.
19. Persist job + metadata artifact; do not write Gemini narrative.

### 12.6 Tests (must pass before M1 done)

20. Unit tests: timestamp/frame helpers if introduced; metadata parsing; error mapping.
21. Integration tests with fixtures: valid short clip, corrupt file, unsupported/missing stream, (if fixture available) rotated phone video.
22. Health endpoint test.
23. Document reproducible command, e.g. `cd services/video_analysis && pytest`.

### 12.7 Explicit non-goals for M1

- No RTMDet / RTMPose
- No MediaPipe production path
- No Gemini calls
- No Flutter UI rename/integration yet
- No deletion of Edge Function yet (leave until cutover)
- No fabricated metrics or coaching text

### 12.8 M1 acceptance criteria

- [ ] `GET /health` returns 200 with ffmpeg/ffprobe detected
- [ ] Valid video job reaches `completed` (or `completed_with_limitations`) with `metadata.json`
- [ ] Invalid video reaches `failed` with error_code + logged stack
- [ ] No coaching report field populated as success fluff
- [ ] pytest green via documented command
- [ ] README lists files created and how to run

### 12.9 Exact next step after M1

Begin **Milestone 2**: RTMDet swimmer detection, persistent track ID, crops, tracking diagnostic output — only after M1 acceptance criteria are met.

---

## 13. Flutter rename note (deferred to Milestone 9)

When integration begins:

- Bottom nav label `Video` → **Elote** or **Elote Lab** (fit nav width)
- Screen header `Video Lab` → **Elote Video Lab**
- Passport CTAs and subscription copy updated to match
- Analysis client switched from Edge Function invoke to async job API

**Not in this deliverable.**

---

## 14. Stop gate

This document plus `docs/video_engine_audit.md` complete the **Initial Deliverable + Phase 1 audit**.

**Do not implement application or service code until explicitly instructed.**  
When implementation is authorized, start **only** with Milestone 1 above.
